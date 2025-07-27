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
# Function to deploy namespace
deploy_namespace() {
    local namespace=$1
    print_status "$BLUE" "Deploying namespace: $namespace"
    kubectl apply -f src/kubernetes/namespaces/all-namespaces.yaml
    print_status "$GREEN" "✓ Namespace $namespace deployed"
}

# Function to deploy secrets management
# Function to deploy secrets management
deploy_secrets_management() {
    print_status "$BLUE" "Deploying secrets management..."
    
    # Check if generated secrets exist, if not generate them
    if [[ ! -f "src/kubernetes/secrets_management/generated-secrets.yaml" ]]; then
        print_status "$YELLOW" "⚠️  Generated secrets not found, creating them..."
        ./src/kubernetes/secrets_management/generate-secrets.sh
    fi
    
    # Deploy generated secrets
    kubectl apply -f src/kubernetes/secrets_management/generated-secrets.yaml
    
    # Deploy External Secrets Operator (optional)
    # kubectl apply -f src/kubernetes/secrets_management/external-secrets-operator.yaml
    
    print_status "$GREEN" "✓ Secrets management deployed"
}

# Function to deploy storage
# Function to deploy storage
deploy_storage() {
    print_status "$BLUE" "Deploying storage classes and volumes..."
    kubectl apply -f src/kubernetes/storage/storage-classes.yaml
    print_status "$GREEN" "✓ Storage classes deployed"
}

# Function to deploy network components
# Function to deploy network components
deploy_network() {
    print_status "$BLUE" "Deploying MetalLB..."
    kubectl apply -f src/kubernetes/network/metallb-config.yaml
    
    print_status "$BLUE" "Deploying Ingress Controller..."
    kubectl apply -f src/kubernetes/network/ingress-config.yaml
    
    print_status "$GREEN" "✓ Network components deployed"
}

# Function to deploy monitoring
# Function to deploy monitoring
deploy_monitoring() {
    print_status "$BLUE" "Deploying monitoring stack..."
    
    # Deploy Prometheus
    kubectl apply -f src/kubernetes/monitoring/prometheus-config.yaml
    kubectl apply -f src/kubernetes/monitoring/prometheus/prometheus-deployment.yaml
    kubectl apply -f src/kubernetes/monitoring/prometheus/prometheus-hpa.yaml
    
    # Deploy Grafana
    kubectl apply -f src/kubernetes/monitoring/grafana/grafana-deployment.yaml
    
    print_status "$GREEN" "✓ Monitoring stack deployed"
}

# Function to deploy CI/CD
# Function to deploy CI/CD
deploy_cicd() {
    print_status "$BLUE" "Deploying CI/CD components..."
    
    # Deploy Jenkins
    kubectl apply -f src/kubernetes/jenkins/jenkins-deployment.yaml
    kubectl apply -f src/kubernetes/jenkins/jenkins-hpa.yaml
    
    print_status "$GREEN" "✓ CI/CD components deployed"
}

# Function to deploy GitOps
# Function to deploy GitOps
deploy_gitops() {
    print_status "$BLUE" "Deploying GitOps components..."
    
    # Deploy ArgoCD
    kubectl apply -f src/kubernetes/gitops/argocd/argocd-install.yaml
    
    print_status "$GREEN" "✓ GitOps components deployed"
}

# Function to deploy artifacts
# Function to deploy artifacts
deploy_artifacts() {
    print_status "$BLUE" "Deploying artifact management..."
    
    # Deploy Artifactory
    kubectl apply -f src/kubernetes/artifacts/artifactory-deployment.yaml
    
    print_status "$GREEN" "✓ Artifact management deployed"
}

# Function to deploy lab applications
# Function to deploy lab applications
deploy_lab_apps() {
    print_status "$BLUE" "Deploying lab applications..."
    
    # Deploy example app
    kubectl apply -f src/kubernetes/lab-stands/example-app.yaml
    kubectl apply -f src/kubernetes/lab-stands/example-app-hpa.yaml
    
    print_status "$GREEN" "✓ Lab applications deployed"
}

# Function to deploy security policies
# Function to deploy security policies
deploy_security_policies() {
    print_status "$BLUE" "Deploying security policies..."
    
    # Deploy Pod Security Policies
    kubectl apply -f src/kubernetes/security/pod-security/pod-security-policies.yaml
    
    # Deploy Network Policies
    kubectl apply -f src/kubernetes/security/network-policies/network-policies.yaml
    
    print_status "$GREEN" "✓ Security policies deployed"
}

# Function to label nodes
# Function to label nodes
label_nodes() {
    print_status "$BLUE" "Labeling nodes..."
    
    # This should be done manually or via Ansible
    # This should be done manually or through Ansible
    print_status "$YELLOW" "⚠ Please label nodes manually using commands from src/kubernetes/nodes/node-labels.yaml"
}

# Function to wait for deployments
# Function to wait for deployments
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
# Function to show service URLs
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
# Main deployment function
main() {
    print_status "$BLUE" "Starting complete deployment of Kubernetes Baremetal Lab..."
    print_status "$BLUE" "Начинаем полное развертывание Kubernetes Baremetal Lab..."
    
    # Check if kubectl is available
    # Check kubectl availability
    if ! command -v kubectl &> /dev/null; then
        print_status "$RED" "✗ kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check cluster connectivity
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_status "$RED" "✗ Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_status "$GREEN" "✓ Connected to Kubernetes cluster"
    
    # Deploy components in order
    # Deploy components in order
    
    # 1. Deploy namespaces
    deploy_namespace "all"
    
    # 2. Deploy secrets management
    deploy_secrets_management
    
    # 3. Deploy storage
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
    
    # 9. Deploy security policies
    deploy_security_policies
    
    # 10. Label nodes (manual step)
    label_nodes
    
    # 11. Wait for deployments
    wait_for_deployments
    
    # 12. Show service URLs
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
# Run main function
main "$@" 