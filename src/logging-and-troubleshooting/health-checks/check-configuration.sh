#!/bin/bash

# Configuration Health Check Script for Kubernetes Cluster
# This script checks configuration settings on both master and worker nodes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/tmp/config-health-check-$(date +%Y%m%d-%H%M%S).log"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
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

# Function to check Kubernetes configuration files
check_k8s_config_files() {
    print_section "Kubernetes Configuration Files Check"
    
    # Check kubelet configuration
    if [[ -f "/var/lib/kubelet/config.yaml" ]]; then
        print_result "OK" "Kubelet config file exists: /var/lib/kubelet/config.yaml"
        
        # Check kubelet config syntax
        if command_exists "kubelet"; then
            if kubelet --config=/var/lib/kubelet/config.yaml --dry-run 2>/dev/null; then
                print_result "OK" "Kubelet configuration syntax is valid"
            else
                print_result "ERROR" "Kubelet configuration syntax is invalid"
            fi
        fi
    else
        print_result "WARNING" "Kubelet config file not found: /var/lib/kubelet/config.yaml"
    fi
    
    # Check kubeadm configuration
    if [[ -f "/etc/kubernetes/kubeadm-config.yaml" ]]; then
        print_result "OK" "Kubeadm config file exists: /etc/kubernetes/kubeadm-config.yaml"
    else
        print_result "INFO" "Kubeadm config file not found (normal for worker nodes)"
    fi
    
    # Check admin.conf
    if [[ -f "/etc/kubernetes/admin.conf" ]]; then
        print_result "OK" "Kubernetes admin config exists: /etc/kubernetes/admin.conf"
    else
        print_result "INFO" "Kubernetes admin config not found (normal for worker nodes)"
    fi
}

# Function to check system configuration
check_system_config() {
    print_section "System Configuration Check"
    
    # Check kernel parameters
    local kernel_params
    kernel_params=(
        "net.bridge.bridge-nf-call-iptables"
        "net.bridge.bridge-nf-call-ip6tables"
        "net.ipv4.ip_forward"
        "vm.swappiness"
        "kernel.keys.root_maxkeys"
        "kernel.keys.root_maxbytes"
    )
    
    for param in "${kernel_params[@]}"; do
        local value
        value=$(sysctl -n "$param" 2>/dev/null || echo "not_set")
        case "$param" in
            "net.bridge.bridge-nf-call-iptables"|"net.bridge.bridge-nf-call-ip6tables")
                if [[ "$value" == "1" ]]; then
                    print_result "OK" "$param = $value"
                else
                    print_result "WARNING" "$param = $value (should be 1)"
                fi
                ;;
            "net.ipv4.ip_forward")
                if [[ "$value" == "1" ]]; then
                    print_result "OK" "$param = $value"
                else
                    print_result "WARNING" "$param = $value (should be 1)"
                fi
                ;;
            "vm.swappiness")
                if [[ "$value" -le 10 ]]; then
                    print_result "OK" "$param = $value"
                else
                    print_result "WARNING" "$param = $value (should be <= 10)"
                fi
                ;;
            *)
                if [[ "$value" != "not_set" ]]; then
                    print_result "OK" "$param = $value"
                else
                    print_result "INFO" "$param not set"
                fi
                ;;
        esac
    done
    
    # Check systemd configuration
    if command_exists "systemctl"; then
        # Check if kubelet service is enabled
        if systemctl is-enabled kubelet >/dev/null 2>&1; then
            print_result "OK" "Kubelet service is enabled"
        else
            print_result "WARNING" "Kubelet service is not enabled"
        fi
        
        # Check if kubelet service is active
        if systemctl is-active kubelet >/dev/null 2>&1; then
            print_result "OK" "Kubelet service is active"
        else
            print_result "ERROR" "Kubelet service is not active"
        fi
    fi
}

# Function to check container runtime configuration
check_container_runtime_config() {
    print_section "Container Runtime Configuration Check"
    
    # Check Docker configuration
    if command_exists "docker"; then
        print_result "OK" "Docker is installed"
        
        # Check Docker daemon configuration
        if [[ -f "/etc/docker/daemon.json" ]]; then
            print_result "OK" "Docker daemon config exists: /etc/docker/daemon.json"
            
            # Check if log driver is configured
            local log_driver
            log_driver=$(jq -r '.log-driver // "not_set"' /etc/docker/daemon.json 2>/dev/null || echo "not_set")
            if [[ "$log_driver" != "not_set" ]]; then
                print_result "OK" "Docker log driver: $log_driver"
            else
                print_result "INFO" "Docker log driver not configured"
            fi
        else
            print_result "INFO" "Docker daemon config not found"
        fi
        
        # Check Docker service status
        if systemctl is-active docker >/dev/null 2>&1; then
            print_result "OK" "Docker service is active"
        else
            print_result "ERROR" "Docker service is not active"
        fi
    fi
    
    # Check containerd configuration
    if command_exists "containerd"; then
        print_result "OK" "Containerd is installed"
        
        # Check containerd configuration
        if [[ -f "/etc/containerd/config.toml" ]]; then
            print_result "OK" "Containerd config exists: /etc/containerd/config.toml"
        else
            print_result "INFO" "Containerd config not found"
        fi
        
        # Check containerd service status
        if systemctl is-active containerd >/dev/null 2>&1; then
            print_result "OK" "Containerd service is active"
        else
            print_result "ERROR" "Containerd service is not active"
        fi
    fi
}

# Function to check network configuration
check_network_config() {
    print_section "Network Configuration Check"
    
    # Check CNI configuration
    if [[ -d "/etc/cni/net.d" ]]; then
        local cni_configs
        cni_configs=$(find /etc/cni/net.d -name "*.conf" -o -name "*.conflist" 2>/dev/null | wc -l)
        if [[ "$cni_configs" -gt 0 ]]; then
            print_result "OK" "CNI configuration files found: $cni_configs"
        else
            print_result "WARNING" "No CNI configuration files found"
        fi
    else
        print_result "WARNING" "CNI configuration directory not found: /etc/cni/net.d"
    fi
    
    # Check iptables rules
    if command_exists "iptables"; then
        local iptables_rules
        iptables_rules=$(iptables -L -n | wc -l)
        if [[ "$iptables_rules" -gt 10 ]]; then
            print_result "OK" "Iptables rules configured: $iptables_rules lines"
        else
            print_result "WARNING" "Few iptables rules found: $iptables_rules lines"
        fi
    fi
    
    # Check DNS configuration
    if [[ -f "/etc/resolv.conf" ]]; then
        local nameservers
        nameservers=$(grep -c "^nameserver" /etc/resolv.conf || echo "0")
        if [[ "$nameservers" -gt 0 ]]; then
            print_result "OK" "DNS nameservers configured: $nameservers"
        else
            print_result "WARNING" "No DNS nameservers configured"
        fi
    fi
}

# Function to check security configuration
check_security_config() {
    print_section "Security Configuration Check"
    
    # Check AppArmor
    if command_exists "apparmor_status"; then
        if apparmor_status --enforced 2>/dev/null | grep -q "enforced"; then
            print_result "OK" "AppArmor is enabled and enforced"
        else
            print_result "WARNING" "AppArmor is not enforced"
        fi
    else
        print_result "INFO" "AppArmor not available"
    fi
    
    # Check SELinux
    if command_exists "getenforce"; then
        local selinux_status
        selinux_status=$(getenforce 2>/dev/null || echo "not_available")
        if [[ "$selinux_status" == "Enforcing" ]]; then
            print_result "OK" "SELinux is enforcing"
        elif [[ "$selinux_status" == "Permissive" ]]; then
            print_result "WARNING" "SELinux is permissive"
        elif [[ "$selinux_status" == "Disabled" ]]; then
            print_result "WARNING" "SELinux is disabled"
        else
            print_result "INFO" "SELinux not available"
        fi
    fi
    
    # Check firewall status
    if command_exists "ufw"; then
        local ufw_status
        ufw_status=$(ufw status 2>/dev/null | head -1 || echo "not_active")
        if [[ "$ufw_status" == *"inactive"* ]]; then
            print_result "INFO" "UFW firewall is inactive"
        else
            print_result "OK" "UFW firewall is active"
        fi
    elif command_exists "firewalld"; then
        if systemctl is-active firewalld >/dev/null 2>&1; then
            print_result "OK" "Firewalld is active"
        else
            print_result "INFO" "Firewalld is inactive"
        fi
    fi
}

# Function to check storage configuration
check_storage_config() {
    print_section "Storage Configuration Check"
    
    # Check if required directories exist
    local required_dirs
    required_dirs=(
        "/var/lib/kubelet"
        "/var/lib/etcd"
        "/var/lib/docker"
        "/var/lib/containerd"
        "/etc/kubernetes"
        "/etc/cni"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_result "OK" "Directory exists: $dir"
        else
            print_result "WARNING" "Directory missing: $dir"
        fi
    done
    
    # Check storage class configuration
    if command_exists "kubectl"; then
        local storage_classes
        storage_classes=$(kubectl get storageclass 2>/dev/null | wc -l || echo "0")
        if [[ "$storage_classes" -gt 1 ]]; then
            print_result "OK" "Storage classes configured: $((storage_classes - 1))"
        else
            print_result "INFO" "No custom storage classes configured"
        fi
    fi
}

# Function to check time synchronization
check_time_sync() {
    print_section "Time Synchronization Check"
    
    # Check system time
    local system_time
    system_time=$(date '+%Y-%m-%d %H:%M:%S')
    print_result "OK" "System time: $system_time"
    
    # Check NTP status
    if command_exists "timedatectl"; then
        local ntp_status
        ntp_status=$(timedatectl status | grep "NTP synchronized" || echo "not_synced")
        if [[ "$ntp_status" == *"yes"* ]]; then
            print_result "OK" "NTP synchronization is active"
        else
            print_result "WARNING" "NTP synchronization is not active"
        fi
    fi
    
    # Check chronyd status
    if command_exists "chronyc"; then
        if chronyc tracking 2>/dev/null | grep -q "Reference ID"; then
            print_result "OK" "Chrony time synchronization is active"
        else
            print_result "WARNING" "Chrony time synchronization is not active"
        fi
    fi
}

# Main function
main() {
    echo -e "${BLUE}Configuration Health Check for Kubernetes Node${NC}"
    echo "Started at: $(date)"
    echo "Log file: $LOG_FILE"
    
    # Check if running as root (optional)
    if [[ $EUID -eq 0 ]]; then
        log_message "INFO" "Running as root user"
    else
        log_message "WARNING" "Not running as root - some checks may be limited"
    fi
    
    # Run all checks
    check_k8s_config_files
    check_system_config
    check_container_runtime_config
    check_network_config
    check_security_config
    check_storage_config
    check_time_sync
    
    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo "Configuration health check completed at: $(date)"
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