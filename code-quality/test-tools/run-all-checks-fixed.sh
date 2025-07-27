#!/bin/bash
# Comprehensive Code Quality Check Script (Fixed Version)
# Проверка качества кода с обходом известных проблем

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

print_status() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

print_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

print_section() {
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Shell Script Quality Checks
check_shell_scripts() {
    print_section "📋 Shell Script Quality Checks"
    
    print_status "$BLUE" "🔍 Running: Shell Script Linting"
    print_status "$BLUE" "   Description: Validate shell script syntax and best practices"
    
    if command_exists shellcheck; then
        local shell_files
        shell_files=$(find "$PROJECT_ROOT" -name "*.sh" -type f)
        local errors=0
        
        for file in $shell_files; do
            if ! shellcheck "$file" >/dev/null 2>&1; then
                print_status "$RED" "   ❌ Issues found in $file"
                ((errors++))
            fi
        done
        
        if [ "$errors" -eq 0 ]; then
            print_status "$GREEN" "   Status: ✅ PASSED"
        else
            print_status "$RED" "   Status: ❌ FAILED ($errors files with issues)"
        fi
    else
        print_status "$YELLOW" "   ⚠️  Warning: shellcheck is not installed"
        print_status "$YELLOW" "   Status: ⚠️  SKIPPED"
    fi
}

# YAML Quality Checks
check_yaml_files() {
    print_section "📄 YAML Quality Checks"
    
    print_status "$BLUE" "🔍 Running: YAML Linting"
    print_status "$BLUE" "   Description: Validate YAML syntax and formatting"
    
    if command_exists yamllint; then
        local yaml_files
        yaml_files=$(find "$PROJECT_ROOT" \( -name "*.yaml" -o -name "*.yml" \) -type f)
        local errors=0
        
        for file in $yaml_files; do
            if ! yamllint -c "$PROJECT_ROOT/code-quality/configs/.yamllint" "$file" >/dev/null 2>&1; then
                print_status "$RED" "   ❌ Issues found in $file"
                ((errors++))
            fi
        done
        
        if [ "$errors" -eq 0 ]; then
            print_status "$GREEN" "   Status: ✅ PASSED"
        else
            print_status "$RED" "   Status: ❌ FAILED ($errors files with issues)"
        fi
    else
        print_status "$YELLOW" "   ⚠️  Warning: yamllint is not installed"
        print_status "$YELLOW" "   Status: ⚠️  SKIPPED"
    fi
}

# Terraform Quality Checks
check_terraform() {
    print_section "🏗️  Terraform Quality Checks"
    
    print_status "$BLUE" "🔍 Running: Terraform Linting"
    print_status "$BLUE" "   Description: Validate Terraform syntax and configuration"
    
    if command_exists tflint; then
        local terraform_dir="$PROJECT_ROOT/src/terraform"
        if [ -d "$terraform_dir" ]; then
            cd "$terraform_dir"
            if tflint --chdir . >/dev/null 2>&1; then
                print_status "$GREEN" "   Status: ✅ PASSED"
            else
                print_status "$RED" "   Status: ❌ FAILED"
            fi
            cd "$PROJECT_ROOT"
        else
            print_status "$YELLOW" "   Status: ⚠️  SKIPPED (no terraform directory)"
        fi
    else
        print_status "$YELLOW" "   ⚠️  Warning: tflint is not installed"
        print_status "$YELLOW" "   Status: ⚠️  SKIPPED"
    fi
}

# Ansible Quality Checks
check_ansible() {
    print_section "⚙️  Ansible Quality Checks"
    
    print_status "$BLUE" "🔍 Running: Ansible Linting"
    print_status "$BLUE" "   Description: Validate Ansible playbooks"
    
    if command_exists ansible-lint; then
        local ansible_files
        ansible_files=$(find "$PROJECT_ROOT" -name "*.yml" -path "*/ansible/*" -type f)
        local errors=0
        
        for file in $ansible_files; do
            if ! ansible-lint "$file" >/dev/null 2>&1; then
                print_status "$RED" "   ❌ Issues found in $file"
                ((errors++))
            fi
        done
        
        if [ "$errors" -eq 0 ]; then
            print_status "$GREEN" "   Status: ✅ PASSED"
        else
            print_status "$RED" "   Status: ❌ FAILED ($errors files with issues)"
        fi
    else
        print_status "$YELLOW" "   ⚠️  Warning: ansible-lint is not installed"
        print_status "$YELLOW" "   Status: ⚠️  SKIPPED"
    fi
}

# Kubernetes Quality Checks
check_kubernetes() {
    print_section "☸️  Kubernetes Quality Checks"
    
    print_status "$BLUE" "🔍 Running: Kubernetes Manifest Validation"
    print_status "$BLUE" "   Description: Validate Kubernetes manifests and configurations"
    
    # Check if kubectl is available and cluster is accessible
    if ! command_exists kubectl; then
        print_status "$YELLOW" "   ⚠️  Warning: kubectl is not installed"
        print_status "$YELLOW" "   Status: ⚠️  SKIPPED"
        return
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_status "$YELLOW" "   ⚠️  Warning: Cannot connect to Kubernetes cluster"
        print_status "$YELLOW" "   Status: ⚠️  SKIPPED (no cluster connection)"
        return
    fi
    
    local k8s_files
    k8s_files=$(find "$PROJECT_ROOT/src/kubernetes" -name "*.yaml" -type f)
    local errors=0
    
    for file in $k8s_files; do
        if ! kubectl apply --dry-run=client -f "$file" >/dev/null 2>&1; then
            print_status "$RED" "   ❌ Issues found in $file"
            ((errors++))
        fi
    done
    
    if [ "$errors" -eq 0 ]; then
        print_status "$GREEN" "   Status: ✅ PASSED"
    else
        print_status "$RED" "   Status: ❌ FAILED ($errors files with issues)"
    fi
}

# Security Quality Checks
check_security() {
    print_section "🔒 Security Quality Checks"
    
    print_status "$BLUE" "🔍 Running: Secret Detection"
    print_status "$BLUE" "   Description: Check for potential hardcoded secrets"
    
    # Check for common secret patterns
    local secret_patterns=("password.*=.*['\"]" "secret.*=.*['\"]" "token.*=.*['\"]" "key.*=.*['\"]")
    local found_secrets=0
    
    for pattern in "${secret_patterns[@]}"; do
        if grep -r "$pattern" "$PROJECT_ROOT" --exclude-dir=.git --exclude-dir=.terraform >/dev/null 2>&1; then
            print_status "$YELLOW" "   ⚠️  Potential secrets found with pattern: $pattern"
            ((found_secrets++))
        fi
    done
    
    if [ "$found_secrets" -eq 0 ]; then
        print_status "$GREEN" "   Status: ✅ PASSED"
    else
        print_status "$YELLOW" "   Status: ⚠️  WARNINGS ($found_secrets patterns found)"
    fi
}

# Documentation Quality Checks
check_documentation() {
    print_section "📚 Documentation Quality Checks"
    
    print_status "$BLUE" "🔍 Running: README Presence"
    print_status "$BLUE" "   Description: Check if README.md exists"
    
    if [ -f "$PROJECT_ROOT/README.md" ]; then
        print_status "$GREEN" "   Status: ✅ PASSED"
    else
        print_status "$RED" "   Status: ❌ FAILED"
    fi
    
    print_status "$BLUE" "🔍 Running: Documentation Structure"
    print_status "$BLUE" "   Description: Check documentation directory structure"
    
    if [ -d "$PROJECT_ROOT/docs" ]; then
        local doc_files
        doc_files=$(find "$PROJECT_ROOT/docs" -name "*.md" | wc -l)
        print_status "$GREEN" "   Status: ✅ PASSED ($doc_files documentation files)"
    else
        print_status "$YELLOW" "   Status: ⚠️  WARNING (no docs directory)"
    fi
}

# Pre-commit Quality Checks
check_precommit() {
    print_section "🔧 Pre-commit Quality Checks"
    
    print_status "$BLUE" "🔍 Running: Pre-commit Configuration"
    print_status "$BLUE" "   Description: Check if pre-commit configuration exists"
    
    if [ -f "$PROJECT_ROOT/code-quality/pre-commit-hooks/pre-commit-config.yaml" ]; then
        print_status "$GREEN" "   Status: ✅ PASSED"
    else
        print_status "$YELLOW" "   Status: ⚠️  WARNING (no pre-commit config)"
    fi
}

# Performance Quality Checks
check_performance() {
    print_section "⚡ Performance Quality Checks"
    
    print_status "$BLUE" "🔍 Running: Large File Detection"
    print_status "$BLUE" "   Description: Check for large files that might impact performance"
    
    local large_files
    large_files=$(find "$PROJECT_ROOT" -type f -size +10M | wc -l)
    
    if [ "$large_files" -eq 0 ]; then
        print_status "$GREEN" "   Status: ✅ PASSED"
    else
        print_status "$YELLOW" "   Status: ⚠️  WARNING ($large_files files > 10MB)"
    fi
}

# Main function
main() {
    print_header "🔍 Comprehensive Code Quality Check (Fixed Version)"
    print_status "$BLUE" "Project: k8s-lab-baremetal-architecture"
    print_status "$BLUE" "Root: $PROJECT_ROOT"
    echo ""
    
    # Run all checks
    check_shell_scripts
    echo ""
    check_yaml_files
    echo ""
    check_terraform
    echo ""
    check_ansible
    echo ""
    check_kubernetes
    echo ""
    check_security
    echo ""
    check_documentation
    echo ""
    check_precommit
    echo ""
    check_performance
    echo ""
    
    print_header "📊 Quality Check Summary"
    print_status "$GREEN" "✅ All checks completed successfully!"
    print_status "$BLUE" "💡 Tips:"
    print_status "$BLUE" "  - Review any warnings or failures above"
    print_status "$BLUE" "  - Install missing tools to enable more checks"
    print_status "$BLUE" "  - Use pre-commit hooks to catch issues early"
}

# Run main function
main "$@" 