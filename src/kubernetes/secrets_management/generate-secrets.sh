#!/bin/bash

# Script to generate secure secrets for Kubernetes
# Скрипт для генерации безопасных секретов для Kubernetes

set -euo pipefail

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

# Function to generate random password
generate_password() {
    local length=${1:-32}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Function to generate base64 encoded value
generate_base64() {
    local value=$1
    echo -n "$value" | base64
}

# Function to create secrets file
create_secrets_file() {
    local output_file="src/kubernetes/secrets_management/generated-secrets.yaml"
    
    print_status "$BLUE" "Generating secure secrets..."
    
    # Generate secure passwords
    JENKINS_PASSWORD=$(generate_password 32)
    GRAFANA_PASSWORD=$(generate_password 32)
    ARGOCD_PASSWORD=$(generate_password 32)
    ARTIFACTORY_PASSWORD=$(generate_password 32)
    POSTGRES_PASSWORD=$(generate_password 32)
    REDIS_PASSWORD=$(generate_password 32)
    
    # Create the secrets file
    cat > "$output_file" << EOF
# Generated Secure Secrets for Kubernetes
# Автоматически сгенерированные безопасные секреты для Kubernetes
# Generated on: $(date)

# Jenkins Admin Secret
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-admin-secret
  namespace: jenkins
  labels:
    app: jenkins
    component: secrets
type: Opaque
data:
  admin-password: $(generate_base64 "$JENKINS_PASSWORD")
  admin-username: $(generate_base64 "admin")
---
# Grafana Admin Secret
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-secret
  namespace: monitoring
  labels:
    app: grafana
    component: secrets
type: Opaque
data:
  admin-password: $(generate_base64 "$GRAFANA_PASSWORD")
  admin-username: $(generate_base64 "admin")
---
# ArgoCD Admin Secret
apiVersion: v1
kind: Secret
metadata:
  name: argocd-admin-secret
  namespace: gitops
  labels:
    app: argocd
    component: secrets
type: Opaque
data:
  admin-password: $(generate_base64 "$ARGOCD_PASSWORD")
  admin-username: $(generate_base64 "admin")
---
# Artifactory Admin Secret
apiVersion: v1
kind: Secret
metadata:
  name: artifactory-admin-secret
  namespace: artifacts
  labels:
    app: artifactory
    component: secrets
type: Opaque
data:
  admin-password: $(generate_base64 "$ARTIFACTORY_PASSWORD")
  admin-username: $(generate_base64 "admin")
---
# Database Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: lab-stands
  labels:
    app: database
    component: secrets
type: Opaque
data:
  postgres-password: $(generate_base64 "$POSTGRES_PASSWORD")
  postgres-user: $(generate_base64 "postgres")
---
# Redis Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: redis-credentials
  namespace: lab-stands
  labels:
    app: redis
    component: secrets
type: Opaque
data:
  redis-password: $(generate_base64 "$REDIS_PASSWORD")
EOF

    print_status "$GREEN" "✓ Secrets generated successfully: $output_file"
    
    # Create passwords file for reference (should be kept secure)
    local passwords_file="src/kubernetes/secrets_management/passwords.txt"
    cat > "$passwords_file" << EOF
# Generated Passwords - KEEP THIS FILE SECURE!
# Сгенерированные пароли - ХРАНИТЕ ЭТОТ ФАЙЛ В БЕЗОПАСНОСТИ!
# Generated on: $(date)

Jenkins Admin Password: $JENKINS_PASSWORD
Grafana Admin Password: $GRAFANA_PASSWORD
ArgoCD Admin Password: $ARGOCD_PASSWORD
Artifactory Admin Password: $ARTIFACTORY_PASSWORD
PostgreSQL Password: $POSTGRES_PASSWORD
Redis Password: $REDIS_PASSWORD

IMPORTANT: Delete this file after deployment and store passwords securely!
ВАЖНО: Удалите этот файл после развертывания и храните пароли в безопасности!
EOF

    print_status "$YELLOW" "⚠️  Passwords saved to: $passwords_file"
    print_status "$YELLOW" "⚠️  Remember to delete passwords file after deployment!"
    
    # Set proper permissions
    chmod 600 "$passwords_file"
    chmod 644 "$output_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --force    Force regeneration of secrets"
    echo ""
    echo "This script generates secure random passwords and creates Kubernetes secrets."
    echo "Скрипт генерирует безопасные случайные пароли и создает секреты Kubernetes."
}

# Main function
main() {
    local force=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    local output_file="src/kubernetes/secrets_management/generated-secrets.yaml"
    
    # Check if secrets file already exists
    if [[ -f "$output_file" && "$force" != "true" ]]; then
        print_status "$YELLOW" "⚠️  Secrets file already exists: $output_file"
        print_status "$YELLOW" "⚠️  Use -f or --force to regenerate"
        exit 0
    fi
    
    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        print_status "$RED" "✗ openssl is not installed"
        print_status "$YELLOW" "Install openssl: sudo apt install openssl"
        exit 1
    fi
    
    # Create secrets
    create_secrets_file
    
    print_status "$GREEN" "✓ Secret generation completed successfully!"
    print_status "$BLUE" "Next steps:"
    echo "1. Review the generated secrets: $output_file"
    echo "2. Apply secrets to cluster: kubectl apply -f $output_file"
    echo "3. Delete passwords file after deployment"
    echo "4. Store passwords securely for future reference"
}

# Run main function
main "$@" 