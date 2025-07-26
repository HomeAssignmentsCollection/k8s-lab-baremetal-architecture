#!/bin/bash

# Helm Deployment Script for Kubernetes Baremetal Lab
# Скрипт развертывания с использованием Helm чартов

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[HELM] ${message}${NC}"
}

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_status "$RED" "✗ $1 is not installed or not in PATH"
        exit 1
    fi
}

# Function to check Helm prerequisites
check_helm_prerequisites() {
    print_status "$BLUE" "Checking Helm prerequisites..."
    
    check_command "helm"
    check_command "kubectl"
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_status "$RED" "✗ Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_status "$GREEN" "✓ Helm prerequisites check passed"
}

# Function to add Helm repositories
add_helm_repositories() {
    print_status "$BLUE" "Adding Helm repositories..."
    
    # Add required repositories
    helm repo add jenkins https://charts.jenkins.io
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add jfrog https://charts.jfrog.io
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add metallb https://metallb.github.io/metallb
    
    # Update repositories
    helm repo update
    
    print_status "$GREEN" "✓ Helm repositories added and updated"
}

# Function to deploy namespaces
deploy_namespaces() {
    print_status "$BLUE" "Deploying namespaces..."
    kubectl apply -f src/kubernetes/namespaces/all-namespaces.yaml
    print_status "$GREEN" "✓ Namespaces deployed"
}

# Function to deploy storage classes
deploy_storage() {
    print_status "$BLUE" "Deploying storage classes..."
    kubectl apply -f src/kubernetes/storage/storage-classes.yaml
    print_status "$GREEN" "✓ Storage classes deployed"
}

# Function to deploy network components
deploy_network() {
    print_status "$BLUE" "Deploying network components..."
    
    # Deploy MetalLB
    helm install metallb metallb/metallb \
        --namespace metallb-system \
        --create-namespace \
        --wait \
        --timeout 5m
    
    # Apply MetalLB configuration
    kubectl apply -f src/kubernetes/network/metallb-config.yaml
    
    # Deploy Ingress Controller
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.nodeSelector.node-type=medium \
        --set controller.service.type=LoadBalancer \
        --wait \
        --timeout 5m
    
    print_status "$GREEN" "✓ Network components deployed"
}

# Function to deploy monitoring stack
deploy_monitoring() {
    print_status "$BLUE" "Deploying monitoring stack..."
    
    # Deploy Prometheus and Grafana
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        -f src/helm/charts/monitoring/values.yaml \
        --wait \
        --timeout 10m
    
    print_status "$GREEN" "✓ Monitoring stack deployed"
}

# Function to deploy Jenkins
deploy_jenkins() {
    print_status "$BLUE" "Deploying Jenkins..."
    
    helm install jenkins jenkins/jenkins \
        --namespace jenkins \
        --create-namespace \
        -f src/helm/charts/jenkins/values.yaml \
        --wait \
        --timeout 10m
    
    print_status "$GREEN" "✓ Jenkins deployed"
}

# Function to deploy ArgoCD
deploy_argocd() {
    print_status "$BLUE" "Deploying ArgoCD..."
    
    helm install argocd argo/argo-cd \
        --namespace gitops \
        --create-namespace \
        -f src/helm/charts/argocd/values.yaml \
        --wait \
        --timeout 10m
    
    print_status "$GREEN" "✓ ArgoCD deployed"
}

# Function to deploy Artifactory
deploy_artifactory() {
    print_status "$BLUE" "Deploying Artifactory..."
    
    helm install artifactory jfrog/artifactory \
        --namespace artifacts \
        --create-namespace \
        -f src/helm/charts/artifactory/values.yaml \
        --wait \
        --timeout 10m
    
    print_status "$GREEN" "✓ Artifactory deployed"
}

# Function to deploy lab applications
deploy_lab_apps() {
    print_status "$BLUE" "Deploying lab applications..."
    kubectl apply -f src/kubernetes/lab-stands/example-app.yaml
    print_status "$GREEN" "✓ Lab applications deployed"
}

# Function to wait for deployments
wait_for_deployments() {
    print_status "$BLUE" "Waiting for deployments to be ready..."
    
    # Wait for critical deployments
    kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n gitops
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
    
    print_status "$GREEN" "✓ All deployments are ready"
}

# Function to show service URLs
show_service_urls() {
    print_status "$BLUE" "Service URLs:"
    echo ""
    echo "Jenkins: http://jenkins.local"
    echo "ArgoCD: http://argocd.local"
    echo "Grafana: http://grafana.local"
    echo "Artifactory: http://artifactory.local"
    echo ""
    print_status "$YELLOW" "⚠ Add these hosts to your /etc/hosts or DNS"
}

# Function to show deployment status
show_deployment_status() {
    print_status "$BLUE" "Deployment Status:"
    echo ""
    kubectl get pods -n jenkins
    echo ""
    kubectl get pods -n gitops
    echo ""
    kubectl get pods -n monitoring
    echo ""
    kubectl get pods -n artifacts
    echo ""
}

# Main deployment function
main() {
    print_status "$BLUE" "Starting Helm-based deployment of Kubernetes Baremetal Lab..."
    print_status "$BLUE" "Начинаем развертывание Kubernetes Baremetal Lab с использованием Helm..."
    
    check_helm_prerequisites
    add_helm_repositories
    deploy_namespaces
    deploy_storage
    deploy_network
    deploy_monitoring
    deploy_jenkins
    deploy_argocd
    deploy_artifactory
    deploy_lab_apps
    
    print_status "$YELLOW" "⚠ Please label your nodes manually using commands from src/kubernetes/nodes/node-labels.yaml"
    
    wait_for_deployments
    show_service_urls
    show_deployment_status
    
    print_status "$GREEN" "Helm deployment completed successfully!"
    print_status "$GREEN" "Развертывание с Helm завершено успешно!"
    
    print_status "$BLUE" "Next steps:"
    echo "1. Label your nodes according to src/kubernetes/nodes/node-labels.yaml"
    echo "2. Configure your DNS or /etc/hosts for service URLs"
    echo "3. Access the services using the provided URLs"
    echo "4. Run verification script: ./src/scripts/verify-installation.sh"
}

# Run main function
main "$@" 