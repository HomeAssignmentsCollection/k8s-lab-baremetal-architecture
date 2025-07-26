#!/bin/bash

# Kubernetes Baremetal Lab - Installation Verification Script
# Скрипт проверки установки Kubernetes Baremetal Lab

set -e

# Colors for output
# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
# Функция для вывода цветного текста
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to check command existence
# Функция для проверки существования команды
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
# Функция для проверки статуса кластера Kubernetes
check_kubernetes_cluster() {
    print_status "$BLUE" "Checking Kubernetes cluster status..."
    
    if ! kubectl cluster-info &> /dev/null; then
        print_status "$RED" "✗ Cannot connect to Kubernetes cluster"
        return 1
    fi
    
    print_status "$GREEN" "✓ Connected to Kubernetes cluster"
    
    # Check nodes
    # Проверка узлов
    print_status "$BLUE" "Checking cluster nodes..."
    local nodes=$(kubectl get nodes --no-headers | wc -l)
    local ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready")
    
    print_status "$GREEN" "✓ Found $nodes nodes, $ready_nodes are ready"
    
    if [ "$nodes" -eq "$ready_nodes" ]; then
        print_status "$GREEN" "✓ All nodes are ready"
    else
        print_status "$YELLOW" "⚠ Some nodes are not ready"
        kubectl get nodes
    fi
    
    # Check system pods
    # Проверка системных подов
    print_status "$BLUE" "Checking system pods..."
    local system_pods=$(kubectl get pods -n kube-system --no-headers | wc -l)
    local running_pods=$(kubectl get pods -n kube-system --no-headers | grep -c "Running")
    
    print_status "$GREEN" "✓ Found $system_pods system pods, $running_pods are running"
    
    if [ "$system_pods" -eq "$running_pods" ]; then
        print_status "$GREEN" "✓ All system pods are running"
    else
        print_status "$YELLOW" "⚠ Some system pods are not running"
        kubectl get pods -n kube-system
    fi
}

# Function to check network connectivity
# Функция для проверки сетевой связности
check_network() {
    print_status "$BLUE" "Checking network connectivity..."
    
    # Check if we can reach the API server
    # Проверка доступности API сервера
    if kubectl get nodes &> /dev/null; then
        print_status "$GREEN" "✓ API server is reachable"
    else
        print_status "$RED" "✗ Cannot reach API server"
        return 1
    fi
    
    # Check DNS resolution
    # Проверка DNS разрешения
    if nslookup kubernetes.default.svc.cluster.local &> /dev/null; then
        print_status "$GREEN" "✓ DNS resolution is working"
    else
        print_status "$YELLOW" "⚠ DNS resolution may have issues"
    fi
}

# Function to check storage
# Функция для проверки хранилища
check_storage() {
    print_status "$BLUE" "Checking storage..."
    
    # Check if default storage class exists
    # Проверка существования класса хранилища по умолчанию
    if kubectl get storageclass &> /dev/null; then
        local storage_classes=$(kubectl get storageclass --no-headers | wc -l)
        print_status "$GREEN" "✓ Found $storage_classes storage classes"
        
        # Check for default storage class
        # Проверка класса хранилища по умолчанию
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
# Функция для проверки мониторинга
check_monitoring() {
    print_status "$BLUE" "Checking monitoring stack..."
    
    # Check if monitoring namespace exists
    # Проверка существования namespace мониторинга
    if kubectl get namespace monitoring &> /dev/null; then
        print_status "$GREEN" "✓ Monitoring namespace exists"
        
        # Check monitoring pods
        # Проверка подов мониторинга
        local monitoring_pods=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l || echo "0")
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
# Функция для проверки логирования
check_logging() {
    print_status "$BLUE" "Checking logging stack..."
    
    # Check if logging namespace exists
    # Проверка существования namespace логирования
    if kubectl get namespace logging &> /dev/null; then
        print_status "$GREEN" "✓ Logging namespace exists"
        
        # Check logging pods
        # Проверка подов логирования
        local logging_pods=$(kubectl get pods -n logging --no-headers 2>/dev/null | wc -l || echo "0")
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
# Функция для проверки ingress
check_ingress() {
    print_status "$BLUE" "Checking ingress controller..."
    
    # Check if ingress-nginx namespace exists
    # Проверка существования namespace ingress-nginx
    if kubectl get namespace ingress-nginx &> /dev/null; then
        print_status "$GREEN" "✓ Ingress-nginx namespace exists"
        
        # Check ingress controller pods
        # Проверка подов ingress контроллера
        local ingress_pods=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | wc -l || echo "0")
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
# Функция для запуска базовых тестов
run_basic_tests() {
    print_status "$BLUE" "Running basic functionality tests..."
    
    # Test namespace creation
    # Тест создания namespace
    local test_namespace="verification-test-$(date +%s)"
    if kubectl create namespace "$test_namespace" &> /dev/null; then
        print_status "$GREEN" "✓ Namespace creation works"
        kubectl delete namespace "$test_namespace" &> /dev/null
    else
        print_status "$RED" "✗ Namespace creation failed"
    fi
    
    # Test pod creation
    # Тест создания пода
    local test_pod="test-pod-$(date +%s)"
    if kubectl run "$test_pod" --image=nginx:alpine --restart=Never &> /dev/null; then
        print_status "$GREEN" "✓ Pod creation works"
        kubectl delete pod "$test_pod" &> /dev/null
    else
        print_status "$RED" "✗ Pod creation failed"
    fi
}

# Main verification function
# Основная функция проверки
main() {
    print_status "$BLUE" "Starting Kubernetes installation verification..."
    print_status "$BLUE" "Начинаем проверку установки Kubernetes..."
    
    # Check required tools
    # Проверка необходимых инструментов
    print_status "$BLUE" "Checking required tools..."
    check_command "kubectl"
    check_command "kubectl"
    
    # Check Kubernetes cluster
    # Проверка кластера Kubernetes
    check_kubernetes_cluster
    
    # Check network
    # Проверка сети
    check_network
    
    # Check storage
    # Проверка хранилища
    check_storage
    
    # Check monitoring
    # Проверка мониторинга
    check_monitoring
    
    # Check logging
    # Проверка логирования
    check_logging
    
    # Check ingress
    # Проверка ingress
    check_ingress
    
    # Run basic tests
    # Запуск базовых тестов
    run_basic_tests
    
    print_status "$GREEN" "Verification completed successfully!"
    print_status "$GREEN" "Проверка завершена успешно!"
}

# Run main function
# Запуск основной функции
main "$@" 