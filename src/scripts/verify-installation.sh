#!/bin/bash

# Kubernetes Baremetal Lab - Installation Verification Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
        print_status "$GREEN" "✓ $cmd is installed"
        return 0
    else
        print_status "$RED" "✗ $cmd is not installed"
        return 1
    fi
}

# Function to check Kubernetes cluster status
check_kubernetes_cluster() {
    print_status "$BLUE" "Checking Kubernetes cluster status..."
    
    if ! kubectl cluster-info &> /dev/null; then
        print_status "$RED" "✗ Cannot connect to Kubernetes cluster"
        return 1
    fi
    
    print_status "$GREEN" "✓ Connected to Kubernetes cluster"
    
    # Check nodes
    print_status "$BLUE" "Checking cluster nodes..."
    local nodes
    local ready_nodes
    nodes=$(kubectl get nodes --no-headers | wc -l)
    ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready")
    
    print_status "$GREEN" "✓ Found $nodes nodes, $ready_nodes are ready"
    
    if [ "$nodes" -eq "$ready_nodes" ]; then
        print_status "$GREEN" "✓ All nodes are ready"
    else
        print_status "$YELLOW" "⚠ Some nodes are not ready"
        kubectl get nodes
    fi
    
    # Check system pods
    print_status "$BLUE" "Checking system pods..."
    local system_pods
    local running_pods
    system_pods=$(kubectl get pods -n kube-system --no-headers | wc -l)
    running_pods=$(kubectl get pods -n kube-system --no-headers | grep -c "Running")
    
    print_status "$GREEN" "✓ Found $system_pods system pods, $running_pods are running"
    
    if [ "$system_pods" -eq "$running_pods" ]; then
        print_status "$GREEN" "✓ All system pods are running"
    else
        print_status "$YELLOW" "⚠ Some system pods are not running"
        kubectl get pods -n kube-system
    fi
}

# Function to check network connectivity
check_network() {
    print_status "$BLUE" "Checking network connectivity..."
    
    # Check if we can reach the API server
    if kubectl get nodes &> /dev/null; then
        print_status "$GREEN" "✓ API server is reachable"
    else
        print_status "$RED" "✗ Cannot reach API server"
        return 1
    fi
    
    # Check DNS resolution
    if nslookup kubernetes.default.svc.cluster.local &> /dev/null; then
        print_status "$GREEN" "✓ DNS resolution is working"
    else
        print_status "$YELLOW" "⚠ DNS resolution may have issues"
    fi
}

# Function to check storage
# Function to check storage
check_storage() {
    print_status "$BLUE" "Checking storage..."
    
    # Check if default storage class exists
    # Check for default storage class existence
    if kubectl get storageclass &> /dev/null; then
        local storage_classes
        storage_classes=$(kubectl get storageclass --no-headers | wc -l)
        print_status "$GREEN" "✓ Found $storage_classes storage classes"
        
        # Check for default storage class
        # Check default storage class
        if kubectl get storageclass | grep -q "default"; then
            print_status "$GREEN" "✓ Default storage class is configured"
        else
            print_status "$YELLOW" "⚠ No default storage class configured"
        fi
    else
        print_status "$YELLOW" "⚠ No storage classes found"
    fi
}

# Function to check monitoring
# Function to check monitoring
check_monitoring() {
    print_status "$BLUE" "Checking monitoring stack..."
    
    # Check if monitoring namespace exists
    # Check for monitoring namespace existence
    if kubectl get namespace monitoring &> /dev/null; then
        print_status "$GREEN" "✓ Monitoring namespace exists"
        
        # Check monitoring pods
        # Check monitoring pods
        local monitoring_pods
        monitoring_pods=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$monitoring_pods" -gt 0 ]; then
            print_status "$GREEN" "✓ Found $monitoring_pods monitoring pods"
        else
            print_status "$YELLOW" "⚠ No monitoring pods found"
        fi
    else
        print_status "$YELLOW" "⚠ Monitoring namespace not found"
    fi
}

# Function to check logging
# Function to check logging
check_logging() {
    print_status "$BLUE" "Checking logging stack..."
    
    # Check if logging namespace exists
    # Check for logging namespace existence
    if kubectl get namespace logging &> /dev/null; then
        print_status "$GREEN" "✓ Logging namespace exists"
        
        # Check logging pods
        # Check logging pods
        local logging_pods
        logging_pods=$(kubectl get pods -n logging --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$logging_pods" -gt 0 ]; then
            print_status "$GREEN" "✓ Found $logging_pods logging pods"
        else
            print_status "$YELLOW" "⚠ No logging pods found"
        fi
    else
        print_status "$YELLOW" "⚠ Logging namespace not found"
    fi
}

# Function to check ingress
# Function to check ingress
check_ingress() {
    print_status "$BLUE" "Checking ingress controller..."
    
    # Check if ingress-nginx namespace exists
    # Check for ingress-nginx namespace existence
    if kubectl get namespace ingress-nginx &> /dev/null; then
        print_status "$GREEN" "✓ Ingress-nginx namespace exists"
        
        # Check ingress controller pods
        # Check ingress controller pods
        local ingress_pods
        ingress_pods=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$ingress_pods" -gt 0 ]; then
            print_status "$GREEN" "✓ Found $ingress_pods ingress controller pods"
        else
            print_status "$YELLOW" "⚠ No ingress controller pods found"
        fi
    else
        print_status "$YELLOW" "⚠ Ingress-nginx namespace not found"
    fi
}

# Function to run basic tests
# Function to run basic tests
run_basic_tests() {
    print_status "$BLUE" "Running basic functionality tests..."
    
    # Test namespace creation
    # Test namespace creation
    local test_namespace
    test_namespace="verification-test-$(date +%s)"
    if kubectl create namespace "$test_namespace" &> /dev/null; then
        print_status "$GREEN" "✓ Namespace creation works"
        kubectl delete namespace "$test_namespace" &> /dev/null
    else
        print_status "$RED" "✗ Namespace creation failed"
    fi
    
    # Test pod creation
    # Test pod creation
    local test_pod
    test_pod="test-pod-$(date +%s)"
    if kubectl run "$test_pod" --image=nginx:alpine --restart=Never &> /dev/null; then
        print_status "$GREEN" "✓ Pod creation works"
        kubectl delete pod "$test_pod" &> /dev/null
    else
        print_status "$RED" "✗ Pod creation failed"
    fi
}

# Main verification function
# Main verification function
main() {
    print_status "$BLUE" "Starting Kubernetes installation verification..."
    print_status "$BLUE" "Начинаем проверку установки Kubernetes..."
    
    # Check required tools
    # Check required tools
    print_status "$BLUE" "Checking required tools..."
    check_command "kubectl"
    check_command "kubectl"
    
    # Check Kubernetes cluster
    # Check Kubernetes cluster
    check_kubernetes_cluster
    
    # Check network
    # Check network
    check_network
    
    # Check storage
    # Check storage
    check_storage
    
    # Check monitoring
    # Check monitoring
    check_monitoring
    
    # Check logging
    # Check logging
    check_logging
    
    # Check ingress
    # Check ingress
    check_ingress
    
    # Run basic tests
    # Run basic tests
    run_basic_tests
    
    print_status "$GREEN" "Verification completed successfully!"
    print_status "$GREEN" "Проверка завершена успешно!"
}

# Run main function
# Run main function
main "$@" 