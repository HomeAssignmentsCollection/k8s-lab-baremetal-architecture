#!/bin/bash

# Kubernetes Components Health Check Script
# This script checks Kubernetes cluster components and their health

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/tmp/kubernetes-health-check-$(date +%Y%m%d-%H%M%S).log"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section header
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
    log_message "INFO" "Starting check: $1"
}

# Function to print result
print_result() {
    local status="$1"
    local message="$2"
    if [[ "$status" == "OK" ]]; then
        echo -e "${GREEN}✓ $message${NC}"
        log_message "INFO" "PASS: $message"
    elif [[ "$status" == "WARNING" ]]; then
        echo -e "${YELLOW}⚠ $message${NC}"
        log_message "WARNING" "$message"
    else
        echo -e "${RED}✗ $message${NC}"
        log_message "ERROR" "$message"
    fi
}

# Function to check kubectl connectivity
check_kubectl_connectivity() {
    print_section "Kubectl Connectivity Check"
    
    if ! command_exists "kubectl"; then
        print_result "ERROR" "kubectl command not found"
        return 1
    fi
    
    # Check cluster info
    if kubectl cluster-info >/dev/null 2>&1; then
        print_result "OK" "Kubectl can connect to cluster"
        
        # Get cluster info
        local cluster_info
        cluster_info=$(kubectl cluster-info | head -1)
        print_result "OK" "Cluster: $cluster_info"
    else
        print_result "ERROR" "Kubectl cannot connect to cluster"
        return 1
    fi
    
    # Check API server health
    if kubectl get --raw='/readyz?verbose' >/dev/null 2>&1; then
        print_result "OK" "API server is healthy"
    else
        print_result "ERROR" "API server is not healthy"
    fi
}

# Function to check node status
check_node_status() {
    print_section "Node Status Check"
    
    if ! command_exists "kubectl"; then
        print_result "ERROR" "kubectl command not found"
        return 1
    fi
    
    # Get all nodes
    local nodes
    nodes=$(kubectl get nodes --no-headers 2>/dev/null || echo "")
    
    if [[ -z "$nodes" ]]; then
        print_result "ERROR" "No nodes found in cluster"
        return 1
    fi
    
    local total_nodes
    total_nodes=$(echo "$nodes" | wc -l)
    local ready_nodes
    ready_nodes=$(echo "$nodes" | grep -c "Ready" || echo "0")
    local not_ready_nodes
    not_ready_nodes=$((total_nodes - ready_nodes))
    
    print_result "OK" "Total nodes: $total_nodes, Ready: $ready_nodes, Not Ready: $not_ready_nodes"
    
    # Check each node individually
    echo "$nodes" | while read -r node_line; do
        local node_name
        node_name=$(echo "$node_line" | awk '{print $1}')
        local node_status
        node_status=$(echo "$node_line" | awk '{print $2}')
        local node_roles
        node_roles=$(echo "$node_line" | awk '{print $3}')
        local node_age
        node_age=$(echo "$node_line" | awk '{print $4}')
        
        if [[ "$node_status" == "Ready" ]]; then
            print_result "OK" "Node $node_name ($node_roles) is Ready (age: $node_age)"
        else
            print_result "ERROR" "Node $node_name ($node_roles) is $node_status (age: $node_age)"
        fi
    done
}

# Function to check control plane components
check_control_plane_components() {
    print_section "Control Plane Components Check"
    
    if ! command_exists "kubectl"; then
        print_result "ERROR" "kubectl command not found"
        return 1
    fi
    
    # Check component status
    local component_status
    component_status=$(kubectl get componentstatuses --no-headers 2>/dev/null || echo "")
    
    if [[ -z "$component_status" ]]; then
        print_result "WARNING" "Component status not available (may be deprecated in newer versions)"
        return 0
    fi
    
    echo "$component_status" | while read -r comp_line; do
        local comp_name
        comp_name=$(echo "$comp_line" | awk '{print $1}')
        local comp_status
        comp_status=$(echo "$comp_line" | awk '{print $2}')
        local comp_message
        comp_message=$(echo "$comp_line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}')
        
        if [[ "$comp_status" == "Healthy" ]]; then
            print_result "OK" "Component $comp_name is Healthy"
        else
            print_result "ERROR" "Component $comp_name is $comp_status: $comp_message"
        fi
    done
    
    # Check control plane pods
    local control_plane_pods
    control_plane_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -E "(kube-apiserver|kube-controller-manager|kube-scheduler|etcd)" || echo "")
    
    if [[ -n "$control_plane_pods" ]]; then
        echo "$control_plane_pods" | while read -r pod_line; do
            local pod_name
            pod_name=$(echo "$pod_line" | awk '{print $1}')
            local pod_status
            pod_status=$(echo "$pod_line" | awk '{print $3}')
            local pod_ready
            pod_ready=$(echo "$pod_line" | awk '{print $2}')
            local pod_restarts
            pod_restarts=$(echo "$pod_line" | awk '{print $4}')
            
            if [[ "$pod_status" == "Running" && "$pod_ready" != "0/1" ]]; then
                print_result "OK" "Control plane pod $pod_name is Running ($pod_ready ready, $pod_restarts restarts)"
            else
                print_result "ERROR" "Control plane pod $pod_name is $pod_status ($pod_ready ready, $pod_restarts restarts)"
            fi
        done
    fi
}

# Function to check worker node components
check_worker_components() {
    print_section "Worker Node Components Check"
    
    # Check kubelet status
    if command_exists "systemctl"; then
        if systemctl is-active kubelet >/dev/null 2>&1; then
            print_result "OK" "Kubelet service is active"
        else
            print_result "ERROR" "Kubelet service is not active"
        fi
        
        # Check kubelet logs for recent errors
        local kubelet_errors
        kubelet_errors=$(journalctl -u kubelet --since "1 hour ago" | grep -i -E "(error|fail|critical)" | tail -5 || echo "")
        
        if [[ -n "$kubelet_errors" ]]; then
            print_result "WARNING" "Recent kubelet errors detected:"
            echo "$kubelet_errors" | while read -r error; do
                echo "  - $error"
            done
        else
            print_result "OK" "No recent kubelet errors"
        fi
    fi
    
    # Check container runtime
    if command_exists "docker"; then
        if systemctl is-active docker >/dev/null 2>&1; then
            print_result "OK" "Docker service is active"
        else
            print_result "ERROR" "Docker service is not active"
        fi
    elif command_exists "containerd"; then
        if systemctl is-active containerd >/dev/null 2>&1; then
            print_result "OK" "Containerd service is active"
        else
            print_result "ERROR" "Containerd service is not active"
        fi
    else
        print_result "ERROR" "No container runtime found"
    fi
    
    # Check kube-proxy
    if command_exists "kubectl"; then
        local kube_proxy_pods
        kube_proxy_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep kube-proxy || echo "")
        
        if [[ -n "$kube_proxy_pods" ]]; then
            echo "$kube_proxy_pods" | while read -r pod_line; do
                local pod_name
                pod_name=$(echo "$pod_line" | awk '{print $1}')
                local pod_status
                pod_status=$(echo "$pod_line" | awk '{print $3}')
                local pod_ready
                pod_ready=$(echo "$pod_line" | awk '{print $2}')
                
                if [[ "$pod_status" == "Running" && "$pod_ready" != "0/1" ]]; then
                    print_result "OK" "Kube-proxy pod $pod_name is Running ($pod_ready ready)"
                else
                    print_result "ERROR" "Kube-proxy pod $pod_name is $pod_status ($pod_ready ready)"
                fi
            done
        fi
    fi
}

# Function to check namespace and resource quotas
check_namespaces_and_quotas() {
    print_section "Namespaces and Resource Quotas Check"
    
    if ! command_exists "kubectl"; then
        print_result "ERROR" "kubectl command not found"
        return 1
    fi
    
    # Check default namespaces
    local default_namespaces
    default_namespaces=("default" "kube-system" "kube-public" "kube-node-lease")
    
    for ns in "${default_namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            print_result "OK" "Namespace $ns exists"
        else
            print_result "ERROR" "Namespace $ns does not exist"
        fi
    done
    
    # Check resource quotas
    local resource_quotas
    resource_quotas=$(kubectl get resourcequota --all-namespaces --no-headers 2>/dev/null || echo "")
    
    if [[ -n "$resource_quotas" ]]; then
        print_result "OK" "Resource quotas configured"
        echo "$resource_quotas" | while read -r quota_line; do
            local quota_namespace
            quota_namespace=$(echo "$quota_line" | awk '{print $1}')
            local quota_name
            quota_name=$(echo "$quota_line" | awk '{print $2}')
            print_result "INFO" "Resource quota $quota_name in namespace $quota_namespace"
        done
    else
        print_result "INFO" "No resource quotas configured"
    fi
}

# Function to check network policies
check_network_policies() {
    print_section "Network Policies Check"
    
    if ! command_exists "kubectl"; then
        print_result "ERROR" "kubectl command not found"
        return 1
    fi
    
    # Check network policies
    local network_policies
    network_policies=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null || echo "")
    
    if [[ -n "$network_policies" ]]; then
        local policy_count
        policy_count=$(echo "$network_policies" | wc -l)
        print_result "OK" "Network policies configured: $policy_count"
        
        echo "$network_policies" | while read -r policy_line; do
            local policy_namespace
            policy_namespace=$(echo "$policy_line" | awk '{print $1}')
            local policy_name
            policy_name=$(echo "$policy_line" | awk '{print $2}')
            print_result "INFO" "Network policy $policy_name in namespace $policy_namespace"
        done
    else
        print_result "INFO" "No network policies configured"
    fi
    
    # Check CNI status
    local cni_pods
    cni_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -E "(calico|cilium|flannel|weave)" || echo "")
    
    if [[ -n "$cni_pods" ]]; then
        echo "$cni_pods" | while read -r pod_line; do
            local pod_name
            pod_name=$(echo "$pod_line" | awk '{print $1}')
            local pod_status
            pod_status=$(echo "$pod_line" | awk '{print $3}')
            local pod_ready
            pod_ready=$(echo "$pod_line" | awk '{print $2}')
            
            if [[ "$pod_status" == "Running" && "$pod_ready" != "0/1" ]]; then
                print_result "OK" "CNI pod $pod_name is Running ($pod_ready ready)"
            else
                print_result "ERROR" "CNI pod $pod_name is $pod_status ($pod_ready ready)"
            fi
        done
    else
        print_result "WARNING" "No CNI pods found"
    fi
}

# Function to check storage components
check_storage_components() {
    print_section "Storage Components Check"
    
    if ! command_exists "kubectl"; then
        print_result "ERROR" "kubectl command not found"
        return 1
    fi
    
    # Check storage classes
    local storage_classes
    storage_classes=$(kubectl get storageclass --no-headers 2>/dev/null || echo "")
    
    if [[ -n "$storage_classes" ]]; then
        local sc_count
        sc_count=$(echo "$storage_classes" | wc -l)
        print_result "OK" "Storage classes configured: $sc_count"
        
        echo "$storage_classes" | while read -r sc_line; do
            local sc_name
            sc_name=$(echo "$sc_line" | awk '{print $1}')
            local sc_provisioner
            sc_provisioner=$(echo "$sc_line" | awk '{print $2}')
            local sc_default
            sc_default=$(echo "$sc_line" | awk '{print $3}')
            
            if [[ "$sc_default" == "true" ]]; then
                print_result "OK" "Default storage class: $sc_name ($sc_provisioner)"
            else
                print_result "INFO" "Storage class: $sc_name ($sc_provisioner)"
            fi
        done
    else
        print_result "WARNING" "No storage classes configured"
    fi
    
    # Check CSI drivers
    local csi_pods
    csi_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -E "(csi-|storage-)" || echo "")
    
    if [[ -n "$csi_pods" ]]; then
        echo "$csi_pods" | while read -r pod_line; do
            local pod_namespace
            pod_namespace=$(echo "$pod_line" | awk '{print $1}')
            local pod_name
            pod_name=$(echo "$pod_line" | awk '{print $2}')
            local pod_status
            pod_status=$(echo "$pod_line" | awk '{print $4}')
            local pod_ready
            pod_ready=$(echo "$pod_line" | awk '{print $3}')
            
            if [[ "$pod_status" == "Running" && "$pod_ready" != "0/1" ]]; then
                print_result "OK" "CSI pod $pod_name in $pod_namespace is Running ($pod_ready ready)"
            else
                print_result "ERROR" "CSI pod $pod_name in $pod_namespace is $pod_status ($pod_ready ready)"
            fi
        done
    else
        print_result "INFO" "No CSI pods found"
    fi
}

# Function to check recent events
check_recent_events() {
    print_section "Recent Events Check"
    
    if ! command_exists "kubectl"; then
        print_result "ERROR" "kubectl command not found"
        return 1
    fi
    
    # Get recent events
    local recent_events
    recent_events=$(kubectl get events --all-namespaces --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -20 || echo "")
    
    if [[ -n "$recent_events" ]]; then
        local error_events
        error_events=$(echo "$recent_events" | grep -i "error\|fail\|critical" || echo "")
        
        if [[ -n "$error_events" ]]; then
            print_result "WARNING" "Recent error events detected:"
            echo "$error_events" | while read -r event_line; do
                local event_time
                event_time=$(echo "$event_line" | awk '{print $1, $2}')
                local event_type
                event_type=$(echo "$event_line" | awk '{print $3}')
                local event_reason
                event_reason=$(echo "$event_line" | awk '{print $4}')
                local event_object
                event_object=$(echo "$event_line" | awk '{print $5}')
                local event_message
                event_message=$(echo "$event_line" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print ""}')
                
                echo "  - [$event_time] $event_type/$event_reason $event_object: $event_message"
            done
        else
            print_result "OK" "No recent error events"
        fi
    else
        print_result "INFO" "No recent events found"
    fi
}

# Main function
main() {
    echo -e "${BLUE}Kubernetes Components Health Check${NC}"
    echo "Started at: $(date)"
    echo "Log file: $LOG_FILE"
    
    # Check if running as root (optional)
    if [[ $EUID -eq 0 ]]; then
        log_message "INFO" "Running as root user"
    else
        log_message "WARNING" "Not running as root - some checks may be limited"
    fi
    
    # Run all checks
    check_kubectl_connectivity
    check_node_status
    check_control_plane_components
    check_worker_components
    check_namespaces_and_quotas
    check_network_policies
    check_storage_components
    check_recent_events
    
    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo "Kubernetes health check completed at: $(date)"
    echo "Log file: $LOG_FILE"
    
    # Count results from log
    local pass_count
    pass_count=$(grep -c "PASS:" "$LOG_FILE" || echo "0")
    local warning_count
    warning_count=$(grep -c "WARNING:" "$LOG_FILE" || echo "0")
    local error_count
    error_count=$(grep -c "ERROR:" "$LOG_FILE" || echo "0")
    
    echo "Results: $pass_count passed, $warning_count warnings, $error_count errors"
    
    if [[ "$error_count" -gt 0 ]]; then
        exit 1
    elif [[ "$warning_count" -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

# Run main function
main "$@" 