#!/bin/bash

# Comprehensive Code Quality Check Runner
# This script runs all code quality checks for the project

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
EXIT_CODE=0
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${BLUE}🔍 Comprehensive Code Quality Check${NC}"
echo "=========================================="
echo -e "Project: ${CYAN}$(basename "$PROJECT_ROOT")${NC}"
echo -e "Root: ${CYAN}$PROJECT_ROOT${NC}"
echo ""

# Function to run a check and track results
run_check() {
    local check_name="$1"
    local check_command="$2"
    local check_description="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -e "${BLUE}🔍 Running: ${CYAN}$check_name${NC}"
    echo -e "   Description: $check_description"
    echo -n "   Status: "
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌ FAILED${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        EXIT_CODE=1
        
        # Show the actual output for failed checks
        echo -e "${YELLOW}   Output:${NC}"
        eval "$check_command" || true
    fi
    echo ""
}

# Function to check if a tool is available
check_tool() {
    local tool_name="$1"
    local install_command="$2"
    
    if ! command -v "$tool_name" &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: $tool_name is not installed${NC}"
        echo -e "   Install with: $install_command"
        return 1
    fi
    return 0
}

# Function to run shell script checks
run_shell_checks() {
    echo -e "${PURPLE}📋 Shell Script Quality Checks${NC}"
    echo "----------------------------------------"
    
    if check_tool "shellcheck" "sudo apt install shellcheck"; then
        run_check \
            "Shell Script Linting" \
            "bash code-quality/linters/lint-shell.sh" \
            "Validate shell script syntax and best practices"
    fi
}

# Function to run Terraform checks
run_terraform_checks() {
    echo -e "${PURPLE}🏗️  Terraform Quality Checks${NC}"
    echo "----------------------------------------"
    
    if check_tool "terraform" "https://www.terraform.io/downloads.html"; then
        run_check \
            "Terraform Linting" \
            "bash code-quality/linters/lint-terraform.sh" \
            "Validate Terraform syntax and configuration"
    fi
}

# Function to run Ansible checks
run_ansible_checks() {
    echo -e "${PURPLE}⚙️  Ansible Quality Checks${NC}"
    echo "----------------------------------------"
    
    if check_tool "ansible" "pip install ansible"; then
        run_check \
            "Ansible Linting" \
            "bash code-quality/linters/lint-ansible.sh" \
            "Validate Ansible playbooks and best practices"
    fi
}

# Function to run Kubernetes checks
run_kubernetes_checks() {
    echo -e "${PURPLE}☸️  Kubernetes Quality Checks${NC}"
    echo "----------------------------------------"
    
    if check_tool "kubectl" "https://kubernetes.io/docs/tasks/tools/install-kubectl/"; then
        run_check \
            "Kubernetes Manifest Validation" \
            "bash code-quality/test-tools/test-manifests.sh" \
            "Validate Kubernetes manifests and configurations"
    fi
}

# Function to run YAML checks
run_yaml_checks() {
    echo -e "${PURPLE}📄 YAML Quality Checks${NC}"
    echo "----------------------------------------"
    
    if check_tool "yamllint" "pip install yamllint"; then
        run_check \
            "YAML Linting" \
            "yamllint -c code-quality/configs/.yamllint src/ configs/ docs/" \
            "Validate YAML syntax and formatting"
    fi
}

# Function to run Markdown checks
run_markdown_checks() {
    echo -e "${PURPLE}📝 Markdown Quality Checks${NC}"
    echo "----------------------------------------"
    
    if check_tool "markdownlint" "npm install -g markdownlint-cli"; then
        run_check \
            "Markdown Linting" \
            "markdownlint docs/ README.md --config code-quality/configs/.markdownlint.json" \
            "Validate Markdown syntax and formatting"
    fi
}

# Function to run security checks
run_security_checks() {
    echo -e "${PURPLE}🔒 Security Quality Checks${NC}"
    echo "----------------------------------------"
    
    # Check for hardcoded secrets
    run_check \
        "Secret Detection" \
        "grep -r -i 'password\|secret\|key\|token' src/ configs/ --exclude-dir=.git --exclude=*.md | head -10" \
        "Check for potential hardcoded secrets"
    
    # Check for public access patterns
    run_check \
        "Public Access Check" \
        "grep -r '0.0.0.0/0\|::/0' src/ configs/ --exclude-dir=.git --exclude=*.md | head -5" \
        "Check for public access configurations"
}

# Function to run documentation checks
run_documentation_checks() {
    echo -e "${PURPLE}📚 Documentation Quality Checks${NC}"
    echo "----------------------------------------"
    
    # Check for README files
    run_check \
        "README Presence" \
        "test -f README.md" \
        "Check if README.md exists"
    
    # Check for documentation structure
    run_check \
        "Documentation Structure" \
        "test -d docs/ && ls docs/" \
        "Check documentation directory structure"
    
    # Check for inline documentation
    run_check \
        "Inline Documentation" \
        "grep -r '^#' src/ --include='*.sh' --include='*.tf' --include='*.yml' --include='*.yaml' | wc -l | test \$1 -gt 10" \
        "Check for inline documentation in code files"
}

# Function to run pre-commit checks
run_precommit_checks() {
    echo -e "${PURPLE}🔧 Pre-commit Quality Checks${NC}"
    echo "----------------------------------------"
    
    if check_tool "pre-commit" "pip install pre-commit"; then
        run_check \
            "Pre-commit Hook Installation" \
            "test -f .git/hooks/pre-commit" \
            "Check if pre-commit hooks are installed"
        
        run_check \
            "Pre-commit Configuration" \
            "test -f code-quality/pre-commit-hooks/pre-commit-config.yaml" \
            "Check if pre-commit configuration exists"
    fi
}

# Function to run performance checks
run_performance_checks() {
    echo -e "${PURPLE}⚡ Performance Quality Checks${NC}"
    echo "----------------------------------------"
    
    # Check for large files
    run_check \
        "Large File Detection" \
        "find . -type f -size +1M -not -path './.git/*' -not -path './node_modules/*' -not -path './venv/*' | head -5" \
        "Check for large files that might impact performance"
    
    # Check for duplicate code patterns
    run_check \
        "Duplicate Code Check" \
        "find src/ -name '*.sh' -exec grep -l 'function ' {} \; | xargs grep -h 'function ' | sort | uniq -d | head -3" \
        "Check for potential duplicate function definitions"
}

# Function to generate summary report
generate_summary() {
    echo -e "${BLUE}📊 Quality Check Summary${NC}"
    echo "=============================="
    echo -e "Total Checks: ${CYAN}$TOTAL_CHECKS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All checks passed!${NC}"
    else
        echo -e "${RED}❌ Some checks failed. Please review the output above.${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "  - Install missing tools to enable more checks"
    echo "  - Review failed checks and fix issues"
    echo "  - Run individual check scripts for detailed output"
    echo "  - Use pre-commit hooks to catch issues early"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    # Run all quality checks
    run_shell_checks
    run_terraform_checks
    run_ansible_checks
    run_kubernetes_checks
    run_yaml_checks
    run_markdown_checks
    run_security_checks
    run_documentation_checks
    run_precommit_checks
    run_performance_checks
    
    # Generate summary
    generate_summary
    
    exit $EXIT_CODE
}

# Run main function
main "$@" 