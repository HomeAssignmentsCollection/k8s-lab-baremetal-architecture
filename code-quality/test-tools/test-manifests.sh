#!/bin/bash

# Kubernetes Manifests Test Suite
# Тестовый набор для валидации манифестов Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[TEST] ${message}${NC}"
}

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_status "$BLUE" "Running test: $test_name"
    
    if eval "$test_command" &> /dev/null; then
        print_status "$GREEN" "✓ PASS: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_status "$RED" "✗ FAIL: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to test YAML syntax
test_yaml_syntax() {
    local manifest_dir="$1"
    local test_name="YAML syntax validation for $manifest_dir"
    local test_command="find $manifest_dir -name '*.yaml' -o -name '*.yml' | xargs -I {} sh -c 'python3 -c \"import yaml; yaml.safe_load(open(\"{}\"))\"'"
    
    run_test "$test_name" "$test_command"
}

# Function to test Kubernetes manifests
test_k8s_manifests() {
    local manifest_dir="$1"
    local test_name="Kubernetes manifest validation for $manifest_dir"
    local test_command="find $manifest_dir -name '*.yaml' -o -name '*.yml' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test namespace definitions
test_namespaces() {
    local test_name="Namespace definitions validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/namespaces/all-namespaces.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test storage classes
test_storage_classes() {
    local test_name="Storage classes validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/storage/storage-classes.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test network components
test_network_components() {
    local test_name="Network components validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/network/metallb-config.yaml && kubectl apply --dry-run=client -f src/kubernetes/network/ingress-config.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test monitoring components
test_monitoring_components() {
    local test_name="Monitoring components validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/monitoring/prometheus-config.yaml && kubectl apply --dry-run=client -f src/kubernetes/monitoring/grafana/grafana-deployment.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test CI/CD components
test_cicd_components() {
    local test_name="CI/CD components validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/jenkins/jenkins-deployment.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test GitOps components
test_gitops_components() {
    local test_name="GitOps components validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/gitops/argocd/argocd-install.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test artifact components
test_artifact_components() {
    local test_name="Artifact components validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/artifacts/artifactory-deployment.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test lab applications
test_lab_applications() {
    local test_name="Lab applications validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/lab-stands/example-app.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test complete deployment
test_complete_deployment() {
    local test_name="Complete deployment validation"
    local test_command="kubectl apply --dry-run=client -f src/kubernetes/namespaces/all-namespaces.yaml && kubectl apply --dry-run=client -f src/kubernetes/storage/storage-classes.yaml && kubectl apply --dry-run=client -f src/kubernetes/network/metallb-config.yaml && kubectl apply --dry-run=client -f src/kubernetes/network/ingress-config.yaml && kubectl apply --dry-run=client -f src/kubernetes/monitoring/prometheus-config.yaml && kubectl apply --dry-run=client -f src/kubernetes/monitoring/grafana/grafana-deployment.yaml && kubectl apply --dry-run=client -f src/kubernetes/jenkins/jenkins-deployment.yaml && kubectl apply --dry-run=client -f src/kubernetes/gitops/argocd/argocd-install.yaml && kubectl apply --dry-run=client -f src/kubernetes/artifacts/artifactory-deployment.yaml && kubectl apply --dry-run=client -f src/kubernetes/lab-stands/example-app.yaml"
    
    run_test "$test_name" "$test_command"
}

# Function to test resource requirements
test_resource_requirements() {
    local test_name="Resource requirements validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'resources:' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test security contexts
test_security_contexts() {
    local test_name="Security contexts validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'securityContext:' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test node selectors
test_node_selectors() {
    local test_name="Node selectors validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'nodeSelector:' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test persistent volumes
test_persistent_volumes() {
    local test_name="Persistent volumes validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'persistentVolumeClaim:' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test services
test_services() {
    local test_name="Services validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'kind: Service' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test ingress
test_ingress() {
    local test_name="Ingress validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'kind: Ingress' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test configmaps
test_configmaps() {
    local test_name="ConfigMaps validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'kind: ConfigMap' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to test secrets
test_secrets() {
    local test_name="Secrets validation"
    local test_command="find src/kubernetes -name '*.yaml' -o -name '*.yml' | xargs grep -l 'kind: Secret' | xargs -I {} kubectl apply --dry-run=client -f {}"
    
    run_test "$test_name" "$test_command"
}

# Function to print test summary
print_summary() {
    echo ""
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Total tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_status "$GREEN" "All tests passed! ✓"
        exit 0
    else
        print_status "$RED" "Some tests failed! ✗"
        exit 1
    fi
}

# Main test function
main() {
    print_status "$BLUE" "Starting Kubernetes manifests test suite..."
    print_status "$BLUE" "Начинаем тестовый набор для манифестов Kubernetes..."
    
    # Check prerequisites
    if ! command -v kubectl &> /dev/null; then
        print_status "$RED" "kubectl is required but not installed"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_status "$RED" "python3 is required but not installed"
        exit 1
    fi
    
    # Run individual component tests
    test_namespaces
    test_storage_classes
    test_network_components
    test_monitoring_components
    test_cicd_components
    test_gitops_components
    test_artifact_components
    test_lab_applications
    
    # Run comprehensive tests
    test_complete_deployment
    test_resource_requirements
    test_security_contexts
    test_node_selectors
    test_persistent_volumes
    test_services
    test_ingress
    test_configmaps
    test_secrets
    
    # Print summary
    print_summary
}

# Run main function
main "$@" 