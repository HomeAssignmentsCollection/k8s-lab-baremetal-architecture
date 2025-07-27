#!/bin/bash

# Docker Linter for Code Quality
# This script validates Dockerfiles and Docker images for security and best practices

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
# PURPLE='\033[0;35m'  # Unused color variable
NC='\033[0m' # No Color

# Configuration
DOCKER_DIRS=("src" "examples" ".")
DOCKER_FILES=()
KUBERNETES_FILES=()
EXIT_CODE=0

echo -e "${BLUE}🐳 Docker Code Quality Check${NC}"
echo "================================="

# Function to check if docker tools are installed
check_docker_tools() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: docker is not installed${NC}"
        echo "For enhanced linting, install docker: https://docs.docker.com/get-docker/"
    fi
    
    if ! command -v hadolint &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: hadolint is not installed${NC}"
        echo "For enhanced linting, install hadolint:"
        echo "  curl -sL -o hadolint \"https://github.com/hadolint/hadolint/releases/latest/download/hadolint-\$(uname -s)-\$(uname -m)\""
        echo "  chmod +x hadolint"
        echo "  sudo mv hadolint /usr/local/bin/"
    fi
    
    if ! command -v trivy &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: trivy is not installed${NC}"
        echo "For security scanning, install trivy:"
        echo "  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
    fi
}

# Function to find docker files
find_docker_files() {
    echo -e "${BLUE}📁 Scanning for Docker files...${NC}"
    
    for dir in "${DOCKER_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                DOCKER_FILES+=("$file")
            done < <(find "$dir" -name "Dockerfile*" -type f -print0)
        fi
    done
    
    if [[ ${#DOCKER_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No Dockerfile found in specified directories${NC}"
    else
        echo -e "${GREEN}✅ Found ${#DOCKER_FILES[@]} Dockerfile(s)${NC}"
    fi
}

# Function to find kubernetes files with images
find_kubernetes_files() {
    echo -e "${BLUE}📁 Scanning for Kubernetes files with images...${NC}"
    
    for dir in "${DOCKER_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                if grep -q "image:" "$file"; then
                    KUBERNETES_FILES+=("$file")
                fi
            done < <(find "$dir" -name "*.yml" -o -name "*.yaml" -type f -print0)
        fi
    done
    
    if [[ ${#KUBERNETES_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No Kubernetes files with images found${NC}"
    else
        echo -e "${GREEN}✅ Found ${#KUBERNETES_FILES[@]} Kubernetes files with images${NC}"
    fi
}

# Function to validate dockerfile syntax
validate_dockerfile_syntax() {
    echo -e "${BLUE}🔧 Validating Dockerfile syntax...${NC}"
    
    for file in "${DOCKER_FILES[@]}"; do
        echo -n "  Checking $(basename "$file")... "
        
        if docker build --no-cache --dry-run -f "$file" . > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
            echo -e "${RED}    Syntax issues found in $file${NC}"
            docker build --no-cache --dry-run -f "$file" .
            EXIT_CODE=1
        fi
    done
}

# Function to run hadolint if available
run_hadolint() {
    if command -v hadolint &> /dev/null; then
        echo -e "${BLUE}🔍 Running hadolint...${NC}"
        
        for file in "${DOCKER_FILES[@]}"; do
            echo -n "  Linting $(basename "$file")... "
            
            if hadolint "$file" > /dev/null 2>&1; then
                echo -e "${GREEN}✅${NC}"
            else
                echo -e "${RED}❌${NC}"
                echo -e "${RED}    hadolint found issues in $file${NC}"
                hadolint "$file"
                EXIT_CODE=1
            fi
        done
    else
        echo -e "${YELLOW}⚠️  Skipping hadolint (not installed)${NC}"
    fi
}

# Function to check for security issues
check_security() {
    echo -e "${BLUE}🔒 Checking for security issues...${NC}"
    
    for file in "${DOCKER_FILES[@]}"; do
        # Check for root user
        if grep -q "USER root" "$file" || ! grep -q "USER " "$file"; then
            echo -e "${YELLOW}⚠️  Consider running as non-root user in $file${NC}"
        fi
        
        # Check for latest tags
        if grep -q "FROM.*:latest" "$file"; then
            echo -e "${YELLOW}⚠️  Using 'latest' tag found in $file - consider using specific version${NC}"
        fi
        
        # Check for secrets in dockerfile
        if grep -q -i "password\|secret\|key\|token" "$file"; then
            echo -e "${YELLOW}⚠️  Potential secret found in $file${NC}"
            grep -n -i "password\|secret\|key\|token" "$file" | head -3
        fi
        
        # Check for unnecessary packages
        if grep -q "apt-get install" "$file" && ! grep -q "apt-get clean" "$file"; then
            echo -e "${YELLOW}⚠️  Consider cleaning apt cache in $file${NC}"
        fi
    done
}

# Function to check for best practices
check_best_practices() {
    echo -e "${BLUE}📋 Checking best practices...${NC}"
    
    for file in "${DOCKER_FILES[@]}"; do
        # Check for multi-stage builds
        if grep -q "FROM.*as" "$file"; then
            echo -e "${GREEN}✅ Multi-stage build found in $file${NC}"
        else
            echo -e "${YELLOW}⚠️  Consider using multi-stage build in $file${NC}"
        fi
        
        # Check for .dockerignore
        local dockerignore_file
        dockerignore_file="$(dirname "$file")/.dockerignore"
        if [[ -f "$dockerignore_file" ]]; then
            echo -e "${GREEN}✅ .dockerignore found for $file${NC}"
        else
            echo -e "${YELLOW}⚠️  Consider adding .dockerignore for $file${NC}"
        fi
        
        # Check for healthcheck
        if grep -q "HEALTHCHECK" "$file"; then
            echo -e "${GREEN}✅ Healthcheck found in $file${NC}"
        else
            echo -e "${YELLOW}⚠️  Consider adding HEALTHCHECK in $file${NC}"
        fi
        
        # Check for proper base images
        if grep -q "FROM alpine" "$file"; then
            echo -e "${GREEN}✅ Alpine base image found in $file${NC}"
        elif grep -q "FROM scratch" "$file"; then
            echo -e "${GREEN}✅ Scratch base image found in $file${NC}"
        fi
    done
}

# Function to check kubernetes image references
check_kubernetes_images() {
    echo -e "${BLUE}☸️  Checking Kubernetes image references...${NC}"
    
    for file in "${KUBERNETES_FILES[@]}"; do
        echo -n "  Checking $(basename "$file")... "
        
        local issues_found=false
        
        # Check for latest tags
        if grep -q "image:.*:latest" "$file"; then
            echo -e "${RED}❌${NC}"
            echo -e "${RED}    'latest' tag found in $file${NC}"
            grep -n "image:.*:latest" "$file"
            issues_found=true
            EXIT_CODE=1
        fi
        
        # Check for missing tags
        if grep -q "image: [^:]*$" "$file"; then
            echo -e "${RED}❌${NC}"
            echo -e "${RED}    Missing tag found in $file${NC}"
            grep -n "image: [^:]*$" "$file"
            issues_found=true
            EXIT_CODE=1
        fi
        
        # Check for insecure registries
        if grep -q "image:.*http://" "$file"; then
            echo -e "${YELLOW}⚠️  Insecure registry found in $file${NC}"
            grep -n "image:.*http://" "$file"
        fi
        
        if [[ "$issues_found" == "false" ]]; then
            echo -e "${GREEN}✅${NC}"
        fi
    done
}

# Function to scan images for vulnerabilities
scan_images() {
    if ! command -v trivy &> /dev/null; then
        echo -e "${YELLOW}⚠️  Skipping image scanning (trivy not installed)${NC}"
        return
    fi
    
    echo -e "${BLUE}🔍 Scanning images for vulnerabilities...${NC}"
    
    # Extract unique images from kubernetes files
    local images=()
    for file in "${KUBERNETES_FILES[@]}"; do
        while IFS= read -r line; do
            if [[ "$line" =~ image:[[:space:]]*(.+) ]]; then
                local image="${BASH_REMATCH[1]}"
                # Remove quotes
                image="${image%\"}"
                image="${image#\"}"
                images+=("$image")
            fi
        done < "$file"
    done
    
    # Remove duplicates
    local unique_images
    mapfile -t unique_images < <(printf "%s\n" "${images[@]}" | sort -u)
    
    for image in "${unique_images[@]}"; do
        echo -n "  Scanning $image... "
        
        if trivy image --severity HIGH,CRITICAL --exit-code 1 "$image" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
            echo -e "${RED}    Vulnerabilities found in $image${NC}"
            trivy image --severity HIGH,CRITICAL "$image" | head -10
            EXIT_CODE=1
        fi
    done
}

# Function to check image sizes
check_image_sizes() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Skipping image size check (docker not installed)${NC}"
        return
    fi
    
    echo -e "${BLUE}📏 Checking image sizes...${NC}"
    
    # Extract unique images from kubernetes files
    local images=()
    for file in "${KUBERNETES_FILES[@]}"; do
        while IFS= read -r line; do
            if [[ "$line" =~ image:[[:space:]]*(.+) ]]; then
                local image="${BASH_REMATCH[1]}"
                # Remove quotes
                image="${image%\"}"
                image="${image#\"}"
                images+=("$image")
            fi
        done < "$file"
    done
    
    # Remove duplicates
    local unique_images
    mapfile -t unique_images < <(printf "%s\n" "${images[@]}" | sort -u)
    
    for image in "${unique_images[@]}"; do
        echo -n "  Checking size of $image... "
        
        # Try to pull image and get size
        if docker pull "$image" > /dev/null 2>&1; then
            local size
            size=$(docker images "$image" --format "table {{.Size}}" | tail -n +2)
            echo -e "${GREEN}✅ $size${NC}"
            
            # Check if image is too large (over 1GB)
            if [[ "$size" =~ ([0-9]+)GB ]] && [[ "${BASH_REMATCH[1]}" -gt 1 ]]; then
                echo -e "${YELLOW}⚠️  Large image detected: $image ($size)${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Could not pull $image${NC}"
        fi
    done
}

# Function to check for deprecated features
check_deprecated_features() {
    echo -e "${BLUE}⚠️  Checking for deprecated features...${NC}"
    
    for file in "${DOCKER_FILES[@]}"; do
        # Check for deprecated MAINTAINER
        if grep -q "MAINTAINER" "$file"; then
            echo -e "${YELLOW}⚠️  MAINTAINER is deprecated, use LABEL in $file${NC}"
        fi
        
        # Check for deprecated ADD for URLs
        if grep -q "ADD.*http" "$file"; then
            echo -e "${YELLOW}⚠️  ADD with URLs is deprecated, use RUN wget/curl in $file${NC}"
        fi
        
        # Check for deprecated EXPOSE format
        if grep -q "EXPOSE.*tcp" "$file"; then
            echo -e "${YELLOW}⚠️  EXPOSE with protocol is deprecated in $file${NC}"
        fi
    done
}

# Function to generate report
generate_report() {
    echo -e "${BLUE}📊 Generating report...${NC}"
    
    local total_dockerfiles=${#DOCKER_FILES[@]}
    local total_k8s_files=${#KUBERNETES_FILES[@]}
    local issues_found=0
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}✅ All Docker files passed quality checks${NC}"
    else
        echo -e "${RED}❌ Issues found in Docker files${NC}"
        issues_found=1
    fi
    
    echo "Summary:"
    echo "  - Dockerfiles checked: $total_dockerfiles"
    echo "  - Kubernetes files with images: $total_k8s_files"
    echo "  - Issues found: $issues_found"
    echo "  - Exit code: $EXIT_CODE"
}

# Main execution
main() {
    check_docker_tools
    find_docker_files
    find_kubernetes_files
    validate_dockerfile_syntax
    run_hadolint
    check_security
    check_best_practices
    check_kubernetes_images
    scan_images
    check_image_sizes
    check_deprecated_features
    generate_report
    
    exit $EXIT_CODE
}

# Run main function
main "$@" 