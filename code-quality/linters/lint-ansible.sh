#!/bin/bash

# Ansible Linter for Code Quality
# This script validates Ansible playbooks and ensures code quality standards

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ANSIBLE_DIRS=("src/ansible" "src/modules")
ANSIBLE_FILES=()
EXIT_CODE=0

echo -e "${BLUE}🔍 Ansible Code Quality Check${NC}"
echo "================================="

# Function to check if ansible is installed
check_ansible() {
    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}❌ Error: ansible is not installed${NC}"
        echo "Please install ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
        exit 1
    fi
    
    if ! command -v ansible-lint &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: ansible-lint is not installed${NC}"
        echo "For enhanced linting, install ansible-lint: pip install ansible-lint"
    fi
}

# Function to find ansible files
find_ansible_files() {
    echo -e "${BLUE}📁 Scanning for Ansible files...${NC}"
    
    for dir in "${ANSIBLE_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                ANSIBLE_FILES+=("$file")
            done < <(find "$dir" -name "*.yml" -o -name "*.yaml" -type f -print0)
        fi
    done
    
    if [[ ${#ANSIBLE_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No Ansible files found in specified directories${NC}"
        return 0
    fi
    
    echo -e "${GREEN}✅ Found ${#ANSIBLE_FILES[@]} Ansible files${NC}"
}

# Function to validate ansible syntax
validate_ansible_syntax() {
    echo -e "${BLUE}🔧 Validating Ansible syntax...${NC}"
    
    for file in "${ANSIBLE_FILES[@]}"; do
        echo -n "  Checking $(basename "$file")... "
        
        if ansible-playbook --syntax-check "$file" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
            echo -e "${RED}    Syntax issues found in $file${NC}"
            ansible-playbook --syntax-check "$file"
            EXIT_CODE=1
        fi
    done
}

# Function to run ansible-lint if available
run_ansible_lint() {
    if command -v ansible-lint &> /dev/null; then
        echo -e "${BLUE}🔍 Running ansible-lint...${NC}"
        
        for file in "${ANSIBLE_FILES[@]}"; do
            echo -n "  Linting $(basename "$file")... "
            
            if ansible-lint "$file" > /dev/null 2>&1; then
                echo -e "${GREEN}✅${NC}"
            else
                echo -e "${RED}❌${NC}"
                echo -e "${RED}    ansible-lint found issues in $file${NC}"
                ansible-lint "$file"
                EXIT_CODE=1
            fi
        done
    else
        echo -e "${YELLOW}⚠️  Skipping ansible-lint (not installed)${NC}"
    fi
}

# Function to check for security issues
check_security() {
    echo -e "${BLUE}🔒 Checking for security issues...${NC}"
    
    for file in "${ANSIBLE_FILES[@]}"; do
        # Check for hardcoded passwords
        if grep -q -i "password.*:" "$file"; then
            echo -e "${YELLOW}⚠️  Potential hardcoded password found in $file${NC}"
            grep -n -i "password.*:" "$file" | head -3
        fi
        
        # Check for become without password
        if grep -q "become: yes" "$file" && ! grep -q "become_method: sudo" "$file"; then
            echo -e "${YELLOW}⚠️  Consider specifying become_method in $file${NC}"
        fi
        
        # Check for shell module usage
        if grep -q "shell:" "$file"; then
            echo -e "${YELLOW}⚠️  Shell module usage found in $file - consider using command module${NC}"
        fi
    done
}

# Function to check for best practices
check_best_practices() {
    echo -e "${BLUE}📋 Checking best practices...${NC}"
    
    for file in "${ANSIBLE_FILES[@]}"; do
        # Check for task names
        if grep -q "- name:" "$file"; then
            echo -e "${GREEN}✅ Task names found in $file${NC}"
        else
            echo -e "${YELLOW}⚠️  Consider adding names to tasks in $file${NC}"
        fi
        
        # Check for handlers
        if grep -q "handlers:" "$file"; then
            echo -e "${GREEN}✅ Handlers found in $file${NC}"
        fi
        
        # Check for variables
        if grep -q "vars:" "$file" || grep -q "{{.*}}" "$file"; then
            echo -e "${GREEN}✅ Variables usage found in $file${NC}"
        fi
    done
}

# Function to validate inventory files
validate_inventory() {
    echo -e "${BLUE}📋 Validating inventory files...${NC}"
    
    for dir in "${ANSIBLE_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                if [[ "$file" == *"inventory"* ]] || [[ "$file" == *"hosts"* ]]; then
                    echo -n "  Validating inventory $(basename "$file")... "
                    
                    if ansible-inventory --list -i "$file" > /dev/null 2>&1; then
                        echo -e "${GREEN}✅${NC}"
                    else
                        echo -e "${RED}❌${NC}"
                        echo -e "${RED}    Inventory validation failed for $file${NC}"
                        EXIT_CODE=1
                    fi
                fi
            done < <(find "$dir" -name "*.yml" -o -name "*.yaml" -o -name "*.ini" -type f -print0)
        fi
    done
}

# Function to check for deprecated modules
check_deprecated_modules() {
    echo -e "${BLUE}⚠️  Checking for deprecated modules...${NC}"
    
    local deprecated_modules=("template" "copy" "file" "lineinfile" "blockinfile")
    
    for file in "${ANSIBLE_FILES[@]}"; do
        for module in "${deprecated_modules[@]}"; do
            if grep -q "$module:" "$file"; then
                echo -e "${YELLOW}⚠️  Module '$module' found in $file - check if it's deprecated${NC}"
            fi
        done
    done
}

# Function to generate report
generate_report() {
    echo -e "${BLUE}📊 Generating report...${NC}"
    
    local total_files=${#ANSIBLE_FILES[@]}
    local issues_found=0
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}✅ All Ansible files passed quality checks${NC}"
    else
        echo -e "${RED}❌ Issues found in Ansible files${NC}"
        issues_found=1
    fi
    
    echo "Summary:"
    echo "  - Total files checked: $total_files"
    echo "  - Issues found: $issues_found"
    echo "  - Exit code: $EXIT_CODE"
}

# Main execution
main() {
    check_ansible
    find_ansible_files
    validate_ansible_syntax
    run_ansible_lint
    check_security
    check_best_practices
    validate_inventory
    check_deprecated_modules
    generate_report
    
    exit $EXIT_CODE
}

# Run main function
main "$@" 