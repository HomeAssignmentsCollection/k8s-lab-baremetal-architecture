#!/bin/bash

# Kubernetes Baremetal Lab - Complete Deployment Script

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

# Function to deploy namespace
# Функция для развертывания namespace
deploy_namespace() {
    local namespace=$1
    print_status "$BLUE" "Deploying namespace: $namespace"
    kubectl apply -f src/kubernetes/namespaces/all-namespaces.yaml
    print_status "$GREEN" "✓ Namespace $namespace deployed"
}

# Function to deploy storage
# Функция для развертывания хранилища
deploy_storage() {
    print_status "$BLUE" "Deploying storage classes and volumes..."
    kubectl apply -f src/kubernetes/storage/storage-classes.yaml
    print_status "$GREEN" "✓ Storage classes deployed"
}

# Function to deploy network components
# Функция для развертывания сетевых компонентов
deploy_network() {
    print_status "$BLUE" "Deploying MetalLB..."
    kubectl apply -f src/kubernetes/network/metallb-config.yaml
    
    print_status "$BLUE" "Deploying Ingress Controller..."
    kubectl apply -f src/kubernetes/network/ingress-config.yaml
    
    print_status "$GREEN" "✓ Network components deployed"
}

# Function to deploy monitoring
# Функция для развертывания мониторинга
deploy_monitoring() {
    print_status "$BLUE" "Deploying monitoring stack..."
    
    # Deploy Prometheus
    kubectl apply -f src/kubernetes/monitoring/prometheus-config.yaml
    
    # Deploy Grafana
    kubectl apply -f src/kubernetes/monitoring/grafana/grafana-deployment.yaml
    
    print_status "$GREEN" "✓ Monitoring stack deployed"
}

# Function to deploy CI/CD
# Функция для развертывания CI/CD
deploy_cicd() {
    print_status "$BLUE" "Deploying CI/CD components..."
    
    # Deploy Jenkins
    kubectl apply -f src/kubernetes/jenkins/jenkins-deployment.yaml
    
    print_status "$GREEN" "✓ CI/CD components deployed"
}

# Function to deploy GitOps
# Функция для развертывания GitOps
deploy_gitops() {
    print_status "$BLUE" "Deploying GitOps components..."
    
    # Deploy ArgoCD
    kubectl apply -f src/kubernetes/gitops/argocd/argocd-install.yaml
    
    print_status "$GREEN" "✓ GitOps components deployed"
}

# Function to deploy artifacts
# Функция для развертывания артефактов
deploy_artifacts() {
    print_status "$BLUE" "Deploying artifact management..."
    
    # Deploy Artifactory
    kubectl apply -f src/kubernetes/artifacts/artifactory-deployment.yaml
    
    print_status "$GREEN" "✓ Artifact management deployed"
}

# Function to deploy lab applications
# Функция для развертывания лабораторных приложений
deploy_lab_apps() {
    print_status "$BLUE" "Deploying lab applications..."
    
    # Deploy example app
    kubectl apply -f src/kubernetes/lab-stands/example-app.yaml
    
    print_status "$GREEN" "✓ Lab applications deployed"
}

# Function to label nodes
# Функция для маркировки узлов
label_nodes() {
    print_status "$BLUE" "Labeling nodes..."
    
    # This should be done manually or via Ansible
    # Это должно быть сделано вручную или через Ansible
    print_status "$YELLOW" "⚠ Please label nodes manually using commands from src/kubernetes/nodes/node-labels.yaml"
}

# Function to wait for deployments
# Функция для ожидания развертываний
wait_for_deployments() {
    print_status "$BLUE" "Waiting for deployments to be ready..."
    
    # Wait for critical deployments
    kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n gitops
    kubectl wait --for=condition=available --timeout=300s deployment/artifactory -n artifacts
    
    print_status "$GREEN" "✓ All deployments are ready"
}

# Function to show service URLs
# Функция для показа URL сервисов
show_service_urls() {
    print_status "$BLUE" "Service URLs:"
    echo ""
    echo "Jenkins: http://jenkins.local (or LoadBalancer IP)"
    echo "Grafana: http://grafana.local (or LoadBalancer IP)"
    echo "ArgoCD: http://argocd.local (or LoadBalancer IP)"
    echo "Artifactory: http://artifactory.local (or LoadBalancer IP)"
    echo "Lab App: http://lab-app.local (or LoadBalancer IP)"
    echo ""
    print_status "$BLUE" "To get LoadBalancer IPs, run:"
    echo "kubectl get svc -A | grep LoadBalancer"
}

# Main deployment function
# Основная функция развертывания
main() {
    print_status "$BLUE" "Starting complete deployment of Kubernetes Baremetal Lab..."
    print_status "$BLUE" "Начинаем полное развертывание Kubernetes Baremetal Lab..."
    
    # Check if kubectl is available
    # Проверка доступности kubectl
    if ! command -v kubectl &> /dev/null; then
        print_status "$RED" "✗ kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check cluster connectivity
    # Проверка связности с кластером
    if ! kubectl cluster-info &> /dev/null; then
        print_status "$RED" "✗ Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_status "$GREEN" "✓ Connected to Kubernetes cluster"
    
    # Deploy components in order
    # Развертывание компонентов по порядку
    
    # 1. Deploy namespaces
    deploy_namespace "all"
    
    # 2. Deploy storage
    deploy_storage
    
    # 3. Deploy network components
    deploy_network
    
    # 4. Deploy monitoring
    deploy_monitoring
    
    # 5. Deploy CI/CD
    deploy_cicd
    
    # 6. Deploy GitOps
    deploy_gitops
    
    # 7. Deploy artifacts
    deploy_artifacts
    
    # 8. Deploy lab applications
    deploy_lab_apps
    
    # 9. Label nodes (manual step)
    label_nodes
    
    # 10. Wait for deployments
    wait_for_deployments
    
    # 11. Show service URLs
    show_service_urls
    
    print_status "$GREEN" "Deployment completed successfully!"
    print_status "$GREEN" "Развертывание завершено успешно!"
    
    print_status "$BLUE" "Next steps:"
    echo "1. Label your nodes according to src/kubernetes/nodes/node-labels.yaml"
    echo "2. Configure your DNS or /etc/hosts for service URLs"
    echo "3. Access the services using the provided URLs"
    echo "4. Run verification script: ./src/scripts/verify-installation.sh"
}

# Run main function
# Запуск основной функции
main "$@" 