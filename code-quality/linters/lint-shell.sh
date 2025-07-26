#!/bin/bash

# Shell Script Linter for Code Quality
# This script validates shell scripts and ensures code quality standards

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SHELL_DIRS=("src/scripts" "src/utils" "code-quality" "configs/scripts")
SHELL_FILES=()
EXIT_CODE=0

echo -e "${BLUE}🔍 Shell Script Code Quality Check${NC}"
echo "======================================"

# Function to check if shellcheck is installed
check_shellcheck() {
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: shellcheck is not installed${NC}"
        echo "For enhanced linting, install shellcheck:"
        echo "  Ubuntu/Debian: sudo apt install shellcheck"
        echo "  CentOS/RHEL: sudo yum install shellcheck"
        echo "  macOS: brew install shellcheck"
    fi
}

# Function to find shell script files
find_shell_files() {
    echo -e "${BLUE}📁 Scanning for shell script files...${NC}"
    
    for dir in "${SHELL_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                SHELL_FILES+=("$file")
            done < <(find "$dir" -name "*.sh" -type f -print0)
        fi
    done
    
    if [[ ${#SHELL_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No shell script files found in specified directories${NC}"
        return 0
    fi
    
    echo -e "${GREEN}✅ Found ${#SHELL_FILES[@]} shell script files${NC}"
}

# Function to validate shell script syntax
validate_shell_syntax() {
    echo -e "${BLUE}🔧 Validating shell script syntax...${NC}"
    
    for file in "${SHELL_FILES[@]}"; do
        echo -n "  Checking $(basename "$file")... "
        
        # Get the shell from shebang or default to bash
        local shell_type="bash"
        if head -1 "$file" | grep -q "^#!"; then
            shell_type=$(head -1 "$file" | sed 's|^#!||' | sed 's|/.*||')
        fi
        
        if bash -n "$file" 2>/dev/null; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
            echo -e "${RED}    Syntax issues found in $file${NC}"
            bash -n "$file"
            EXIT_CODE=1
        fi
    done
}

# Function to run shellcheck if available
run_shellcheck() {
    if command -v shellcheck &> /dev/null; then
        echo -e "${BLUE}🔍 Running shellcheck...${NC}"
        
        for file in "${SHELL_FILES[@]}"; do
            echo -n "  Linting $(basename "$file")... "
            
            if shellcheck "$file" > /dev/null 2>&1; then
                echo -e "${GREEN}✅${NC}"
            else
                echo -e "${RED}❌${NC}"
                echo -e "${RED}    shellcheck found issues in $file${NC}"
                shellcheck "$file"
                EXIT_CODE=1
            fi
        done
    else
        echo -e "${YELLOW}⚠️  Skipping shellcheck (not installed)${NC}"
    fi
}

# Function to check for security issues
check_security() {
    echo -e "${BLUE}🔒 Checking for security issues...${NC}"
    
    for file in "${SHELL_FILES[@]}"; do
        # Check for set -euo pipefail
        if ! grep -q "set -euo pipefail" "$file"; then
            echo -e "${YELLOW}⚠️  Consider adding 'set -euo pipefail' to $file for better error handling${NC}"
        fi
        
        # Check for hardcoded passwords
        if grep -q -i "password.*=" "$file"; then
            echo -e "${YELLOW}⚠️  Potential hardcoded password found in $file${NC}"
            grep -n -i "password.*=" "$file" | head -3
        fi
        
        # Check for eval usage
        if grep -q "eval " "$file"; then
            echo -e "${YELLOW}⚠️  eval usage found in $file - consider alternatives${NC}"
        fi
        
        # Check for command injection vulnerabilities
        if grep -q "\$(" "$file" && grep -q "echo.*\$" "$file"; then
            echo -e "${YELLOW}⚠️  Potential command injection vulnerability in $file${NC}"
        fi
    done
}

# Function to check for best practices
check_best_practices() {
    echo -e "${BLUE}📋 Checking best practices...${NC}"
    
    for file in "${SHELL_FILES[@]}"; do
        # Check for shebang
        if ! head -1 "$file" | grep -q "^#!"; then
            echo -e "${YELLOW}⚠️  Missing shebang in $file${NC}"
        else
            echo -e "${GREEN}✅ Shebang found in $file${NC}"
        fi
        
        # Check for function documentation
        if grep -q "^[[:space:]]*function " "$file" || grep -q "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*()" "$file"; then
            echo -e "${GREEN}✅ Functions found in $file${NC}"
        fi
        
        # Check for variable quoting
        if grep -q "echo.*\$[A-Z_]" "$file" && ! grep -q "echo.*\"\$[A-Z_]" "$file"; then
            echo -e "${YELLOW}⚠️  Consider quoting variables in $file${NC}"
        fi
        
        # Check for proper exit codes
        if grep -q "exit " "$file"; then
            echo -e "${GREEN}✅ Exit codes found in $file${NC}"
        fi
    done
}

# Function to check for portability
check_portability() {
    echo -e "${BLUE}🌐 Checking for portability...${NC}"
    
    for file in "${SHELL_FILES[@]}"; do
        # Check for bash-specific features
        if grep -q "declare " "$file" || grep -q "local " "$file"; then
            echo -e "${GREEN}✅ Bash features found in $file${NC}"
        fi
        
        # Check for POSIX compliance
        if grep -q "function " "$file"; then
            echo -e "${YELLOW}⚠️  'function' keyword found in $file - not POSIX compliant${NC}"
        fi
        
        # Check for system-specific commands
        if grep -q "apt-get\|yum\|dnf\|pacman" "$file"; then
            echo -e "${YELLOW}⚠️  Package manager commands found in $file - may not be portable${NC}"
        fi
    done
}

# Function to check for performance issues
check_performance() {
    echo -e "${BLUE}⚡ Checking for performance issues...${NC}"
    
    for file in "${SHELL_FILES[@]}"; do
        # Check for unnecessary subshells
        if grep -q "\$(echo " "$file"; then
            echo -e "${YELLOW}⚠️  Unnecessary subshell found in $file${NC}"
        fi
        
        # Check for inefficient loops
        if grep -q "for.*in.*\$(ls" "$file"; then
            echo -e "${YELLOW}⚠️  Consider using 'for file in *' instead of 'for file in \$(ls)' in $file${NC}"
        fi
        
        # Check for command substitution in loops
        if grep -q "while.*read.*\$(command" "$file"; then
            echo -e "${YELLOW}⚠️  Command substitution in loop found in $file - consider alternatives${NC}"
        fi
    done
}

# Function to check for documentation
check_documentation() {
    echo -e "${BLUE}📚 Checking documentation...${NC}"
    
    for file in "${SHELL_FILES[@]}"; do
        # Check for header comments
        if head -5 "$file" | grep -q "^#.*[A-Z]"; then
            echo -e "${GREEN}✅ Header documentation found in $file${NC}"
        else
            echo -e "${YELLOW}⚠️  Consider adding header documentation to $file${NC}"
        fi
        
        # Check for function documentation
        if grep -q "^[[:space:]]*function " "$file" || grep -q "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*()" "$file"; then
            if grep -A1 "^[[:space:]]*function " "$file" | grep -q "^#" || grep -A1 "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*()" "$file" | grep -q "^#"; then
                echo -e "${GREEN}✅ Function documentation found in $file${NC}"
            else
                echo -e "${YELLOW}⚠️  Consider adding documentation to functions in $file${NC}"
            fi
        fi
    done
}

# Function to generate report
generate_report() {
    echo -e "${BLUE}📊 Generating report...${NC}"
    
    local total_files=${#SHELL_FILES[@]}
    local issues_found=0
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}✅ All shell script files passed quality checks${NC}"
    else
        echo -e "${RED}❌ Issues found in shell script files${NC}"
        issues_found=1
    fi
    
    echo "Summary:"
    echo "  - Total files checked: $total_files"
    echo "  - Issues found: $issues_found"
    echo "  - Exit code: $EXIT_CODE"
}

# Main execution
main() {
    check_shellcheck
    find_shell_files
    validate_shell_syntax
    run_shellcheck
    check_security
    check_best_practices
    check_portability
    check_performance
    check_documentation
    generate_report
    
    exit $EXIT_CODE
}

# Run main function
main "$@" 