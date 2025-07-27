#!/bin/bash

# Kubernetes Cluster Health Check Utility

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to check command existence
check_command() {
    local cmd=$1
    if command -v "$cmd" &> /dev/null; then
        print_status "$GREEN" "✓ $cmd is available"
        return 0
    else
        print_status "$RED" "✗ $cmd is not available"
        return 1
    fi
}

# Function to check cluster connectivity
check_cluster_connectivity() {
    print_status "$BLUE" "Checking cluster connectivity..."
    
    if kubectl cluster-info &> /dev/null; then
        print_status "$GREEN" "✓ Cluster is accessible"
        return 0
    else
        print_status "$RED" "✗ Cannot connect to cluster"
        return 1
    fi
}

# Function to check nodes
check_nodes() {
    print_status "$BLUE" "Checking cluster nodes..."
    
    local nodes
    local ready_nodes
    nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")
    
    if [ "$nodes" -gt 0 ]; then
        print_status "$GREEN" "✓ Found $nodes nodes, $ready_nodes are ready"
        
        if [ "$nodes" -eq "$ready_nodes" ]; then
            print_status "$GREEN" "✓ All nodes are ready"
        else
            print_status "$YELLOW" "⚠ Some nodes are not ready"
            kubectl get nodes
        fi
    else
        print_status "$RED" "✗ No nodes found"
        return 1
    fi
}

# Function to check system pods
check_system_pods() {
    print_status "$BLUE" "Checking system pods..."
    
    local system_pods
    local running_pods
    system_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l || echo "0")
    running_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    
    if [ "$system_pods" -gt 0 ]; then
        print_status "$GREEN" "✓ Found $system_pods system pods, $running_pods are running"
        
        if [ "$system_pods" -eq "$running_pods" ]; then
            print_status "$GREEN" "✓ All system pods are running"
        else
            print_status "$YELLOW" "⚠ Some system pods are not running"
            kubectl get pods -n kube-system
        fi
    else
        print_status "$RED" "✗ No system pods found"
        return 1
    fi
}

# Function to check application pods
check_application_pods() {
    print_status "$BLUE" "Checking application pods..."
    
    local namespaces=("jenkins" "monitoring" "gitops" "artifacts" "lab-stands")
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &> /dev/null; then
            local pods
            local running_pods
            pods=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l || echo "0")
            running_pods=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
            
            if [ "$pods" -gt 0 ]; then
                print_status "$GREEN" "✓ $ns: $pods pods, $running_pods running"
            else
                print_status "$YELLOW" "⚠ $ns: No pods found"
            fi
        else
            print_status "$YELLOW" "⚠ Namespace $ns not found"
        fi
    done
}

# Function to check services
check_services() {
    print_status "$BLUE" "Checking services..."
    
    local loadbalancer_services
    local clusterip_services
    loadbalancer_services=$(kubectl get svc --all-namespaces --no-headers 2>/dev/null | grep -c "LoadBalancer" || echo "0")
    clusterip_services=$(kubectl get svc --all-namespaces --no-headers 2>/dev/null | grep -c "ClusterIP" || echo "0")
    
    print_status "$GREEN" "✓ Found $loadbalancer_services LoadBalancer services"
    print_status "$GREEN" "✓ Found $clusterip_services ClusterIP services"
}

# Function to check storage
check_storage() {
    print_status "$BLUE" "Checking storage..."
    
    if kubectl get storageclass &> /dev/null; then
        local storage_classes
        storage_classes=$(kubectl get storageclass --no-headers | wc -l)
        print_status "$GREEN" "✓ Found $storage_classes storage classes"
        
        # Check for default storage class
        if kubectl get storageclass | grep -q "default"; then
            print_status "$GREEN" "✓ Default storage class is configured"
        else
            print_status "$YELLOW" "⚠ No default storage class configured"
        fi
    else
        print_status "$YELLOW" "⚠ No storage classes found"
    fi
    
    # Check persistent volumes
    local pvs
    pvs=$(kubectl get pv --no-headers 2>/dev/null | wc -l || echo "0")
    print_status "$GREEN" "✓ Found $pvs persistent volumes"
}

# Function to check network policies
check_network_policies() {
    print_status "$BLUE" "Checking network policies..."
    
    local network_policies
    network_policies=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l || echo "0")
    print_status "$GREEN" "✓ Found $network_policies network policies"
}

# Function to check resource usage
check_resource_usage() {
    print_status "$BLUE" "Checking resource usage..."
    
    # Check node resource usage
    kubectl top nodes 2>/dev/null || print_status "$YELLOW" "⚠ Cannot get node resource usage (metrics-server not available)"
    
    # Check pod resource usage
    kubectl top pods --all-namespaces 2>/dev/null || print_status "$YELLOW" "⚠ Cannot get pod resource usage (metrics-server not available)"
}

# Function to check events
check_events() {
    print_status "$BLUE" "Checking recent events..."
    
    local recent_events
    recent_events=$(kubectl get events --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -10 || echo "")
    
    if [ -n "$recent_events" ]; then
        print_status "$YELLOW" "Recent events:"
        echo "$recent_events"
    else
        print_status "$GREEN" "✓ No recent events found"
    fi
}

# Function to check logs for errors
check_logs() {
    print_status "$BLUE" "Checking for error logs..."
    
    # Check kube-system logs for errors
    local error_logs
    error_logs=$(kubectl logs -n kube-system --all-containers --tail=50 2>/dev/null | grep -i "error\|fail\|exception" | head -5 || echo "")
    
    if [ -n "$error_logs" ]; then
        print_status "$YELLOW" "Found error logs:"
        echo "$error_logs"
    else
        print_status "$GREEN" "✓ No error logs found"
    fi
}

# Function to generate health report
generate_health_report() {
    print_status "$BLUE" "Generating health report..."
    
    local report_file
    report_file="cluster-health-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Kubernetes Cluster Health Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo ""
        echo "Cluster Information:"
        kubectl cluster-info
        echo ""
        echo "Node Information:"
        kubectl get nodes -o wide
        echo ""
        echo "System Pods:"
        kubectl get pods -n kube-system
        echo ""
        echo "Services:"
        kubectl get svc --all-namespaces
        echo ""
        echo "Storage Classes:"
        kubectl get storageclass
        echo ""
        echo "Persistent Volumes:"
        kubectl get pv
        echo ""
        echo "Recent Events:"
        kubectl get events --sort-by='.lastTimestamp'
    } > "$report_file"
    
    print_status "$GREEN" "✓ Health report saved to $report_file"
}

# Main health check function
main() {
    print_status "$BLUE" "Starting Kubernetes cluster health check..."
    print_status "$BLUE" "Начинаем проверку здоровья кластера Kubernetes..."
    
    # Check prerequisites
    check_command "kubectl"
    
    # Check cluster connectivity
    if ! check_cluster_connectivity; then
        print_status "$RED" "Cannot proceed without cluster connectivity"
        exit 1
    fi
    
    # Run all health checks
    check_nodes
    check_system_pods
    check_application_pods
    check_services
    check_storage
    check_network_policies
    check_resource_usage
    check_events
    check_logs
    
    # Generate report
    generate_health_report
    
    print_status "$GREEN" "Health check completed!"
    print_status "$GREEN" "Проверка здоровья завершена!"
}

# Run main function
main "$@" 