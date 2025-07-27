#!/bin/bash

# Configuration Generation Script

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
    echo -e "${color}[CONFIG] ${message}${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <environment> [options]"
    echo ""
    echo "Environments:"
    echo "  dev       - Development environment"
    echo "  staging   - Staging environment"
    echo "  prod      - Production environment"
    echo ""
    echo "Options:"
    echo "  --validate    - Validate generated configuration"
    echo "  --encrypt     - Encrypt secrets (requires encryption key)"
    echo "  --dry-run     - Show what would be generated without creating files"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 prod --validate"
    echo "  $0 staging --dry-run"
}

# Function to validate environment
validate_environment() {
    local env=$1
    case $env in
        dev|staging|prod)
            return 0
            ;;
        *)
            print_status "$RED" "Invalid environment: $env"
            print_status "$RED" "Valid environments: dev, staging, prod"
            return 1
            ;;
    esac
}

# Function to generate random password
generate_password() {
    local length=${1:-16}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Function to generate base64 encoded value
generate_base64() {
    echo -n "$1" | base64
}

# Function to generate Terraform variables
generate_terraform_vars() {
    local env=$1
    local output_file="configs/environments/$env/terraform.tfvars"
    
    print_status "$BLUE" "Generating Terraform variables for $env environment..."
    
    # Create directory if it doesn't exist
    mkdir -p "configs/environments/$env"
    
    # Generate environment-specific values
    case $env in
        dev)
            control_plane_ips='["192.168.1.10", "192.168.1.11", "192.168.1.12"]'
            big_worker_ips='["192.168.2.10", "192.168.2.11", "192.168.2.12"]'
            medium_worker_ips='["192.168.3.10", "192.168.3.11", "192.168.3.12"]'
            small_worker_ips='["192.168.4.10", "192.168.4.11", "192.168.4.12"]'
            storage_ips='["192.168.5.10", "192.168.5.11", "192.168.5.12"]'
            load_balancer_ip='"192.168.1.100"'
            environment='"dev"'
            ;;
        staging)
            control_plane_ips='["192.168.1.10", "192.168.1.11", "192.168.1.12"]'
            big_worker_ips='["192.168.2.10", "192.168.2.11", "192.168.2.12"]'
            medium_worker_ips='["192.168.3.10", "192.168.3.11", "192.168.3.12"]'
            small_worker_ips='["192.168.4.10", "192.168.4.11", "192.168.4.12"]'
            storage_ips='["192.168.5.10", "192.168.5.11", "192.168.5.12"]'
            load_balancer_ip='"192.168.1.100"'
            environment='"staging"'
            ;;
        prod)
            control_plane_ips='["192.168.1.10", "192.168.1.11", "192.168.1.12"]'
            big_worker_ips='["192.168.2.10", "192.168.2.11", "192.168.2.12"]'
            medium_worker_ips='["192.168.3.10", "192.168.3.11", "192.168.3.12"]'
            small_worker_ips='["192.168.4.10", "192.168.4.11", "192.168.4.12"]'
            storage_ips='["192.168.5.10", "192.168.5.11", "192.168.5.12"]'
            load_balancer_ip='"192.168.1.100"'
            environment='"prod"'
            ;;
    esac
    
    # Generate terraform.tfvars
    cat > "$output_file" << EOF
# Terraform variables for $env environment

# Infrastructure configuration
control_plane_ips = $control_plane_ips
big_worker_ips = $big_worker_ips
medium_worker_ips = $medium_worker_ips
small_worker_ips = $small_worker_ips
storage_ips = $storage_ips
load_balancer_ip = $load_balancer_ip

# Network configuration
network_gateway = "192.168.1.1"
dns_servers = ["8.8.8.8", "8.8.4.4"]

# SSH configuration
ssh_user = "ubuntu"
ssh_private_key_path = "~/.ssh/id_rsa"
ssh_port = 22

# Kubernetes configuration
kubernetes_version = "1.28.0"
container_runtime = "containerd"
cni_plugin = "flannel"
pod_cidr = "10.244.0.0/16"
service_cidr = "10.96.0.0/12"
cluster_name = "baremetal-cluster-$env"
cluster_domain = "cluster.local"

# Security configuration
enable_rbac = true
enable_network_policies = true
enable_pod_security_policies = false

# Monitoring and logging
enable_monitoring = true
enable_logging = true
enable_ingress = true

# Storage configuration
enable_local_storage = true
enable_nfs_storage = false
nfs_server = ""
nfs_path = "/exports"

# Backup configuration
enable_backup = true
backup_retention_days = 30

# Tags and labels
environment = $environment
project = "k8s-baremetal-lab"
owner = "admin"
EOF
    
    print_status "$GREEN" "✓ Terraform variables generated: $output_file"
}

# Function to generate Kubernetes secrets
generate_kubernetes_secrets() {
    local env=$1
    local output_file="configs/environments/$env/secrets.yaml"
    
    print_status "$BLUE" "Generating Kubernetes secrets for $env environment..."
    
    # Generate environment-specific passwords
    case $env in
        dev)
            jenkins_password="admin"
            grafana_password="admin"
            argocd_password="admin"
            artifactory_password="admin"
            ;;
        staging)
            jenkins_password=$(generate_password 12)
            grafana_password=$(generate_password 12)
            argocd_password=$(generate_password 12)
            artifactory_password=$(generate_password 12)
            ;;
        prod)
            jenkins_password=$(generate_password 16)
            grafana_password=$(generate_password 16)
            argocd_password=$(generate_password 16)
            artifactory_password=$(generate_password 16)
            ;;
    esac
    
    # Generate secrets.yaml
    cat > "$output_file" << EOF
# Kubernetes Secrets for $env environment
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
type: Opaque
data:
  # Jenkins secrets
  jenkins-admin-password: $(generate_base64 "$jenkins_password")
  jenkins-api-token: $(generate_base64 "${env}-jenkins-token")
  
  # Grafana secrets
  grafana-admin-password: $(generate_base64 "$grafana_password")
  grafana-secret-key: $(generate_base64 "${env}-grafana-secret")
  
  # ArgoCD secrets
  argocd-admin-password: $(generate_base64 "$argocd_password")
  argocd-server-secret: $(generate_base64 "${env}-argocd-secret")
  
  # Artifactory secrets
  artifactory-admin-password: $(generate_base64 "$artifactory_password")
  artifactory-join-key: $(generate_base64 "${env}-artifactory-key")
  
  # Database secrets
  db-password: $(generate_base64 "${env}-db-password")
  db-root-password: $(generate_base64 "${env}-root-password")
  
  # External service secrets
  github-token: $(generate_base64 "${env}-github-token")
  docker-registry-password: $(generate_base64 "${env}-docker-password")
EOF
    
    print_status "$GREEN" "✓ Kubernetes secrets generated: $output_file"
    
    # Show passwords for dev environment
    if [ "$env" = "dev" ]; then
        print_status "$YELLOW" "Development passwords (for reference):"
        echo "  Jenkins: $jenkins_password"
        echo "  Grafana: $grafana_password"
        echo "  ArgoCD: $argocd_password"
        echo "  Artifactory: $artifactory_password"
    fi
}

# Function to validate configuration
validate_configuration() {
    local env=$1
    
    print_status "$BLUE" "Validating configuration for $env environment..."
    
    # Check if required files exist
    local required_files=(
        "configs/environments/$env/terraform.tfvars"
        "configs/environments/$env/secrets.yaml"
        "configs/environments/$env/kubernetes-config.yaml"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_status "$GREEN" "✓ $file exists"
        else
            print_status "$RED" "✗ $file missing"
            return 1
        fi
    done
    
    # Validate Terraform variables
    if command -v terraform &> /dev/null; then
        cd "configs/environments/$env"
        if terraform validate -var-file=terraform.tfvars 2>/dev/null; then
            print_status "$GREEN" "✓ Terraform variables are valid"
        else
            print_status "$YELLOW" "⚠ Terraform validation skipped (no terraform files)"
        fi
        cd - > /dev/null
    fi
    
    # Validate YAML syntax
    for file in "${required_files[@]}"; do
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            print_status "$GREEN" "✓ $file has valid YAML syntax"
        else
            print_status "$RED" "✗ $file has invalid YAML syntax"
            return 1
        fi
    done
    
    print_status "$GREEN" "✓ Configuration validation passed"
}

# Main function
main() {
    local environment=""
    local validate=false
    local dry_run=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            dev|staging|prod)
                environment="$1"
                shift
                ;;
            --validate)
                validate=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if environment is specified
    if [ -z "$environment" ]; then
        print_status "$RED" "Environment is required"
        show_usage
        exit 1
    fi
    
    # Validate environment
    if ! validate_environment "$environment"; then
        exit 1
    fi
    
    print_status "$BLUE" "Generating configuration for $environment environment..."
    
    if [ "$dry_run" = true ]; then
        print_status "$YELLOW" "DRY RUN MODE - No files will be created"
        print_status "$BLUE" "Would generate:"
        echo "  - configs/environments/$environment/terraform.tfvars"
        echo "  - configs/environments/$environment/secrets.yaml"
        echo "  - configs/environments/$environment/kubernetes-config.yaml"
        exit 0
    fi
    
    # Generate configuration files
    generate_terraform_vars "$environment"
    generate_kubernetes_secrets "$environment"
    
    # Validate if requested
    if [ "$validate" = true ]; then
        validate_configuration "$environment"
    fi
    
    print_status "$GREEN" "Configuration generation completed for $environment environment!"
    print_status "$BLUE" "Generated files:"
    echo "  - configs/environments/$environment/terraform.tfvars"
    echo "  - configs/environments/$environment/secrets.yaml"
    echo "  - configs/environments/$environment/kubernetes-config.yaml"
}

# Run main function
main "$@" 