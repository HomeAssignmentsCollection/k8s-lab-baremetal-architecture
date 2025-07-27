#!/bin/bash

# Kubernetes Manifests Linter

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Lint counters
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0
WARNINGS=0

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[LINT] ${message}${NC}"
}

# Function to check YAML formatting
check_yaml_formatting() {
    local file="$1"
    local issues=0
    
    # Check for trailing spaces
    if grep -q " $" "$file"; then
        print_status "$YELLOW" "⚠ Trailing spaces found in $file"
        issues=$((issues + 1))
    fi
    
    # Check for tabs instead of spaces
    if grep -q $'\t' "$file"; then
        print_status "$YELLOW" "⚠ Tabs found instead of spaces in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper indentation (2 spaces)
    if grep -q "^[[:space:]]*[[:space:]][[:space:]]*[[:space:]]" "$file"; then
        print_status "$YELLOW" "⚠ Inconsistent indentation in $file"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to check Kubernetes best practices
check_k8s_best_practices() {
    local file="$1"
    local issues=0
    
    # Check for resource limits
    if grep -q "kind: Deployment\|kind: StatefulSet\|kind: DaemonSet" "$file" && ! grep -q "resources:" "$file"; then
        print_status "$YELLOW" "⚠ No resource limits defined in $file"
        issues=$((issues + 1))
    fi
    
    # Check for security contexts
    if grep -q "kind: Deployment\|kind: StatefulSet\|kind: DaemonSet" "$file" && ! grep -q "securityContext:" "$file"; then
        print_status "$YELLOW" "⚠ No security context defined in $file"
        issues=$((issues + 1))
    fi
    
    # Check for image tags
    if grep -q "image:" "$file" && grep -q "image: .*:latest" "$file"; then
        print_status "$YELLOW" "⚠ Using 'latest' tag in $file"
        issues=$((issues + 1))
    fi
    
    # Check for hardcoded secrets
    if grep -q "password\|secret\|key" "$file" && grep -q "=.*['\"][^'\"]*['\"]" "$file"; then
        print_status "$RED" "✗ Hardcoded secrets found in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper labels
    if grep -q "kind: Deployment\|kind: StatefulSet\|kind: DaemonSet\|kind: Service" "$file" && ! grep -q "labels:" "$file"; then
        print_status "$YELLOW" "⚠ No labels defined in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper annotations
    if grep -q "kind: Ingress" "$file" && ! grep -q "annotations:" "$file"; then
        print_status "$YELLOW" "⚠ No annotations defined for Ingress in $file"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to check naming conventions
check_naming_conventions() {
    local file="$1"
    local issues=0
    
    # Check for lowercase names
    if grep -q "name: [A-Z]" "$file"; then
        print_status "$YELLOW" "⚠ Names should be lowercase in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper namespace naming
    if grep -q "kind: Namespace" "$file" && grep -q "name: [A-Z]" "$file"; then
        print_status "$YELLOW" "⚠ Namespace names should be lowercase in $file"
        issues=$((issues + 1))
    fi
    
    # Check for consistent naming patterns
    if grep -q "app:" "$file" && ! grep -q "app: [a-z0-9-]*" "$file"; then
        print_status "$YELLOW" "⚠ App labels should follow kebab-case in $file"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to check resource definitions
check_resource_definitions() {
    local file="$1"
    local issues=0
    
    # Check for proper API versions
    if grep -q "apiVersion:" "$file" && grep -q "apiVersion: v1" "$file" && grep -q "kind: Deployment\|kind: StatefulSet\|kind: DaemonSet" "$file"; then
        print_status "$RED" "✗ Invalid API version for Deployment/StatefulSet/DaemonSet in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper resource types
    if grep -q "kind: Deployment" "$file" && ! grep -q "spec:" "$file"; then
        print_status "$RED" "✗ Missing spec section in Deployment in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper service types
    if grep -q "kind: Service" "$file" && ! grep -q "type:" "$file"; then
        print_status "$YELLOW" "⚠ Service type not specified in $file"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to check networking
check_networking() {
    local file="$1"
    local issues=0
    
    # Check for proper port definitions
    if grep -q "kind: Service" "$file" && ! grep -q "ports:" "$file"; then
        print_status "$YELLOW" "⚠ No ports defined in Service in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper ingress rules
    if grep -q "kind: Ingress" "$file" && ! grep -q "rules:" "$file"; then
        print_status "$YELLOW" "⚠ No rules defined in Ingress in $file"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to check storage
check_storage() {
    local file="$1"
    local issues=0
    
    # Check for proper PVC definitions
    if grep -q "kind: PersistentVolumeClaim" "$file" && ! grep -q "storageClassName:" "$file"; then
        print_status "$YELLOW" "⚠ No storage class specified in PVC in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper volume mounts
    if grep -q "volumeMounts:" "$file" && ! grep -q "volumes:" "$file"; then
        print_status "$YELLOW" "⚠ Volume mounts without volume definitions in $file"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to check monitoring and logging
check_monitoring_logging() {
    local file="$1"
    local issues=0
    
    # Check for proper probes
    if grep -q "kind: Deployment\|kind: StatefulSet" "$file" && ! grep -q "livenessProbe\|readinessProbe" "$file"; then
        print_status "$YELLOW" "⚠ No health checks defined in $file"
        issues=$((issues + 1))
    fi
    
    # Check for proper logging
    if grep -q "kind: Deployment\|kind: StatefulSet" "$file" && ! grep -q "stdout\|stderr" "$file"; then
        print_status "$YELLOW" "⚠ No logging configuration in $file"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to lint a single file
lint_file() {
    local file="$1"
    local total_issues=0
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
    print_status "$BLUE" "Linting $file"
    
    # Run all checks
    check_yaml_formatting "$file"
    total_issues=$((total_issues + $?))
    
    check_k8s_best_practices "$file"
    total_issues=$((total_issues + $?))
    
    check_naming_conventions "$file"
    total_issues=$((total_issues + $?))
    
    check_resource_definitions "$file"
    total_issues=$((total_issues + $?))
    
    check_networking "$file"
    total_issues=$((total_issues + $?))
    
    check_storage "$file"
    total_issues=$((total_issues + $?))
    
    check_monitoring_logging "$file"
    total_issues=$((total_issues + $?))
    
    if [ $total_issues -eq 0 ]; then
        print_status "$GREEN" "✓ $file passed all checks"
        PASSED_FILES=$((PASSED_FILES + 1))
    else
        print_status "$RED" "✗ $file has $total_issues issues"
        FAILED_FILES=$((FAILED_FILES + 1))
        WARNINGS=$((WARNINGS + total_issues))
    fi
}

# Function to generate lint report
generate_lint_report() {
    local report_file
    report_file="k8s-lint-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Kubernetes Manifests Lint Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo ""
        echo "Summary:"
        echo "Total files: $TOTAL_FILES"
        echo "Passed: $PASSED_FILES"
        echo "Failed: $FAILED_FILES"
        echo "Total issues: $WARNINGS"
        echo ""
        echo "Recommendations:"
        echo "1. Always define resource limits"
        echo "2. Use specific image tags instead of 'latest'"
        echo "3. Define security contexts"
        echo "4. Use proper labels and annotations"
        echo "5. Follow naming conventions (lowercase, kebab-case)"
        echo "6. Define health checks (liveness/readiness probes)"
        echo "7. Configure proper logging"
        echo "8. Use secrets management instead of hardcoded values"
    } > "$report_file"
    
    print_status "$GREEN" "✓ Lint report saved to $report_file"
}

# Function to print summary
print_summary() {
    echo ""
    echo "=================================="
    echo "Lint Summary"
    echo "=================================="
    echo "Total files: $TOTAL_FILES"
    echo "Passed: $PASSED_FILES"
    echo "Failed: $FAILED_FILES"
    echo "Total issues: $WARNINGS"
    echo ""
    
    if [ $FAILED_FILES -eq 0 ]; then
        print_status "$GREEN" "All files passed linting! ✓"
        exit 0
    else
        print_status "$RED" "Some files failed linting! ✗"
        exit 1
    fi
}

# Main lint function
main() {
    print_status "$BLUE" "Starting Kubernetes manifests linting..."
    print_status "$BLUE" "Начинаем анализ манифестов Kubernetes..."
    
    # Find all YAML files
    local yaml_files
    yaml_files=$(find src/kubernetes -name "*.yaml" -o -name "*.yml" 2>/dev/null || echo "")
    
    if [ -z "$yaml_files" ]; then
        print_status "$YELLOW" "No YAML files found to lint"
        exit 0
    fi
    
    # Lint each file
    for file in $yaml_files; do
        if [ -f "$file" ]; then
            lint_file "$file"
        fi
    done
    
    # Generate report
    generate_lint_report
    
    # Print summary
    print_summary
}

# Run main function
main "$@" 