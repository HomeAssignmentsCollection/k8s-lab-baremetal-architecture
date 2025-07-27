#!/bin/bash
set -e

# CNI Deployment Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl first."
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    fi
    
    log_info "Prerequisites check passed!"
}

# Function to remove existing CNI
remove_existing_cni() {
    log_step "Removing existing CNI..."
    
    # Check if Flannel is installed
    if kubectl get pods -n kube-flannel &> /dev/null; then
        log_warn "Flannel detected. Removing..."
        kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml --ignore-not-found=true
    fi
    
    # Check if Calico is installed
    if kubectl get pods -n calico-system &> /dev/null; then
        log_warn "Calico detected. Removing..."
        kubectl delete -f src/kubernetes/network/calico/calico-install.yaml --ignore-not-found=true
    fi
    
    # Check if Cilium is installed
    if kubectl get pods -n cilium &> /dev/null; then
        log_warn "Cilium detected. Removing..."
        kubectl delete -f src/kubernetes/network/cilium/cilium-install.yaml --ignore-not-found=true
    fi
    
    # Check if Weave is installed
    if kubectl get pods -n kube-system -l name=weave-net &> /dev/null; then
        log_warn "Weave detected. Removing..."
        kubectl delete -f https://github.com/weaveworks/weave/releases/download/latest_release/weave-daemonset-k8s.yaml --ignore-not-found=true
    fi
    
    log_info "Existing CNI removed!"
}

# Function to deploy Flannel
deploy_flannel() {
    log_step "Deploying Flannel CNI..."
    
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    
    log_info "Waiting for Flannel pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s
    
    log_info "Flannel deployed successfully!"
}

# Function to deploy Calico
deploy_calico() {
    log_step "Deploying Calico CNI..."
    
    kubectl apply -f src/kubernetes/network/calico/calico-install.yaml
    
    log_info "Waiting for Calico operator to be ready..."
    kubectl wait --for=condition=ready pod -l app=calico-operator -n calico-system --timeout=300s
    
    log_info "Waiting for Calico pods to be ready..."
    kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n calico-system --timeout=300s
    
    log_info "Calico deployed successfully!"
}

# Function to deploy Cilium
deploy_cilium() {
    log_step "Deploying Cilium CNI..."
    
    # Check kernel version
    KERNEL_VERSION=$(uname -r | cut -d. -f1,2)
    REQUIRED_VERSION="4.9"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$KERNEL_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        log_error "Cilium requires Linux kernel 4.9 or higher. Current version: $KERNEL_VERSION"
    fi
    
    kubectl apply -f src/kubernetes/network/cilium/cilium-install.yaml
    
    log_info "Waiting for Cilium pods to be ready..."
    kubectl wait --for=condition=ready pod -l k8s-app=cilium -n cilium --timeout=300s
    
    log_info "Cilium deployed successfully!"
}

# Function to deploy Weave
deploy_weave() {
    log_step "Deploying Weave CNI..."
    
    kubectl apply -f https://github.com/weaveworks/weave/releases/download/latest_release/weave-daemonset-k8s.yaml
    
    log_info "Waiting for Weave pods to be ready..."
    kubectl wait --for=condition=ready pod -l name=weave-net -n kube-system --timeout=300s
    
    log_info "Weave deployed successfully!"
}

# Function to verify CNI installation
verify_cni() {
    local cni_type=$1
    log_step "Verifying $cni_type installation..."
    
    case $cni_type in
        "flannel")
            kubectl get pods -n kube-flannel
            kubectl get nodes -o wide
            ;;
        "calico")
            kubectl get pods -n calico-system
            kubectl get nodes -o wide
            ;;
        "cilium")
            kubectl get pods -n cilium
            kubectl get nodes -o wide
            ;;
        "weave")
            kubectl get pods -n kube-system -l name=weave-net
            kubectl get nodes -o wide
            ;;
    esac
    
    log_info "CNI verification completed!"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <cni-type>"
    echo ""
    echo "CNI Types:"
    echo "  flannel  - Simple and reliable CNI"
    echo "  calico   - Enterprise-grade security CNI"
    echo "  cilium   - Next-generation eBPF-based CNI"
    echo "  weave    - Simple and autonomous CNI"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --force    Force removal of existing CNI"
    echo "  -v, --verify   Verify installation after deployment"
    echo ""
    echo "Examples:"
    echo "  $0 flannel                    # Deploy Flannel"
    echo "  $0 calico --force             # Force deploy Calico"
    echo "  $0 cilium --verify            # Deploy Cilium and verify"
}

# Main function
main() {
    local cni_type=""
    local force_remove=false
    local verify_install=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                force_remove=true
                shift
                ;;
            -v|--verify)
                verify_install=true
                shift
                ;;
            flannel|calico|cilium|weave)
                cni_type=$1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$cni_type" ]; then
        log_error "Please specify a CNI type"
        show_usage
        exit 1
    fi
    
    log_info "Starting CNI deployment: $cni_type"
    
    # Check prerequisites
    check_prerequisites
    
    # Remove existing CNI if force flag is set
    if [ "$force_remove" = true ]; then
        remove_existing_cni
    fi
    
    # Deploy selected CNI
    case $cni_type in
        "flannel")
            deploy_flannel
            ;;
        "calico")
            deploy_calico
            ;;
        "cilium")
            deploy_cilium
            ;;
        "weave")
            deploy_weave
            ;;
        *)
            log_error "Unknown CNI type: $cni_type"
            exit 1
            ;;
    esac
    
    # Verify installation if requested
    if [ "$verify_install" = true ]; then
        verify_cni "$cni_type"
    fi
    
    log_info "CNI deployment completed successfully!"
    log_info "CNI Type: $cni_type"
    log_info "You can now deploy your applications!"
}

# Error handling
trap 'log_error "An error occurred. Exiting..."; exit 1' ERR

# Run main function
main "$@" 