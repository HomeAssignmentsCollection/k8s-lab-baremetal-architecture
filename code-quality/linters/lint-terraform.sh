#!/bin/bash

# Terraform Linter for Code Quality
# This script validates Terraform configurations and ensures code quality standards

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIRS=("src/terraform" "src/infrastructure")
TERRAFORM_FILES=()
EXIT_CODE=0

echo -e "${BLUE}🔍 Terraform Code Quality Check${NC}"
echo "=================================="

# Function to check if terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Error: terraform is not installed${NC}"
        echo "Please install terraform: https://www.terraform.io/downloads.html"
        exit 1
    fi
    
    if ! command -v tflint &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: tflint is not installed${NC}"
        echo "For enhanced linting, install tflint: https://github.com/terraform-linters/tflint"
    fi
}

# Function to find terraform files
find_terraform_files() {
    echo -e "${BLUE}📁 Scanning for Terraform files...${NC}"
    
    for dir in "${TERRAFORM_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                TERRAFORM_FILES+=("$file")
            done < <(find "$dir" -name "*.tf" -type f -print0)
        fi
    done
    
    if [[ ${#TERRAFORM_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No Terraform files found in specified directories${NC}"
        return 0
    fi
    
    echo -e "${GREEN}✅ Found ${#TERRAFORM_FILES[@]} Terraform files${NC}"
}

# Function to validate terraform syntax
validate_terraform_syntax() {
    echo -e "${BLUE}🔧 Validating Terraform syntax...${NC}"
    
    for file in "${TERRAFORM_FILES[@]}"; do
        echo -n "  Checking $(basename "$file")... "
        
        if terraform fmt -check -diff "$file" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
            echo -e "${RED}    Format issues found in $file${NC}"
            terraform fmt -diff "$file"
            EXIT_CODE=1
        fi
    done
}

# Function to validate terraform configuration
validate_terraform_config() {
    echo -e "${BLUE}⚙️  Validating Terraform configuration...${NC}"
    
    for dir in "${TERRAFORM_DIRS[@]}"; do
        if [[ -d "$dir" ]] && [[ -f "$dir/main.tf" ]]; then
            echo -n "  Validating $dir... "
            
            # Change to directory for terraform commands
            pushd "$dir" > /dev/null
            
            if terraform init -backend=false > /dev/null 2>&1; then
                if terraform validate > /dev/null 2>&1; then
                    echo -e "${GREEN}✅${NC}"
                else
                    echo -e "${RED}❌${NC}"
                    echo -e "${RED}    Configuration validation failed in $dir${NC}"
                    terraform validate
                    EXIT_CODE=1
                fi
            else
                echo -e "${RED}❌${NC}"
                echo -e "${RED}    Failed to initialize terraform in $dir${NC}"
                EXIT_CODE=1
            fi
            
            popd > /dev/null
        fi
    done
}

# Function to run tflint if available
run_tflint() {
    if command -v tflint &> /dev/null; then
        echo -e "${BLUE}🔍 Running tflint...${NC}"
        
        for dir in "${TERRAFORM_DIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                echo -n "  Linting $dir... "
                
                if tflint "$dir" > /dev/null 2>&1; then
                    echo -e "${GREEN}✅${NC}"
                else
                    echo -e "${RED}❌${NC}"
                    echo -e "${RED}    tflint found issues in $dir${NC}"
                    tflint "$dir"
                    EXIT_CODE=1
                fi
            fi
        done
    else
        echo -e "${YELLOW}⚠️  Skipping tflint (not installed)${NC}"
    fi
}

# Function to check for security issues
check_security() {
    echo -e "${BLUE}🔒 Checking for security issues...${NC}"
    
    for file in "${TERRAFORM_FILES[@]}"; do
        # Check for hardcoded secrets
        if grep -q -i "password\|secret\|key\|token" "$file"; then
            echo -e "${YELLOW}⚠️  Potential secret found in $file${NC}"
            grep -n -i "password\|secret\|key\|token" "$file" | head -3
        fi
        
        # Check for public access
        if grep -q "0.0.0.0/0\|::/0" "$file"; then
            echo -e "${YELLOW}⚠️  Public access found in $file${NC}"
            grep -n "0.0.0.0/0\|::/0" "$file"
        fi
    done
}

# Function to check for best practices
check_best_practices() {
    echo -e "${BLUE}📋 Checking best practices...${NC}"
    
    for file in "${TERRAFORM_FILES[@]}"; do
        # Check for resource naming conventions
        if grep -q "resource.*{" "$file"; then
            # Check for descriptive names
            if grep -q "resource.*\"[a-z0-9_]*\"" "$file"; then
                echo -e "${GREEN}✅ Resource naming looks good in $file${NC}"
            fi
        fi
        
        # Check for tags
        if grep -q "resource.*{" "$file" && ! grep -q "tags.*{" "$file"; then
            echo -e "${YELLOW}⚠️  Consider adding tags to resources in $file${NC}"
        fi
    done
}

# Function to generate report
generate_report() {
    echo -e "${BLUE}📊 Generating report...${NC}"
    
    local total_files=${#TERRAFORM_FILES[@]}
    local issues_found=0
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}✅ All Terraform files passed quality checks${NC}"
    else
        echo -e "${RED}❌ Issues found in Terraform files${NC}"
        issues_found=1
    fi
    
    echo "Summary:"
    echo "  - Total files checked: $total_files"
    echo "  - Issues found: $issues_found"
    echo "  - Exit code: $EXIT_CODE"
}

# Main execution
main() {
    check_terraform
    find_terraform_files
    validate_terraform_syntax
    validate_terraform_config
    run_tflint
    check_security
    check_best_practices
    generate_report
    
    exit $EXIT_CODE
}

# Run main function
main "$@" 