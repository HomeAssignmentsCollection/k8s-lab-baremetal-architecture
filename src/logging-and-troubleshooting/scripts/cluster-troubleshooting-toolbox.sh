#!/bin/bash

# Kubernetes Cluster Troubleshooting Toolbox
# Main script that orchestrates all health checks and maintenance tasks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Configuration
LOG_DIR="/tmp/k8s-troubleshooting"
BACKUP_DIR="/var/backups/etcd"
REPORT_DIR="/tmp/k8s-reports"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print header
print_header() {
    echo -e "\n${PURPLE}================================${NC}"
    echo -e "${PURPLE}  Kubernetes Troubleshooting Toolbox${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo "Started at: $(date)"
    echo "Script directory: $SCRIPT_DIR"
    echo "Log directory: $LOG_DIR"
}

# Function to print section header
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
    log_message "INFO" "Starting: $1"
}

# Function to print result
print_result() {
    local status="$1"
    local message="$2"
    if [[ "$status" == "OK" ]]; then
        echo -e "${GREEN}✓ $message${NC}"
        log_message "INFO" "SUCCESS: $message"
    elif [[ "$status" == "WARNING" ]]; then
        echo -e "${YELLOW}⚠ $message${NC}"
        log_message "WARNING" "$message"
    else
        echo -e "${RED}✗ $message${NC}"
        log_message "ERROR" "$message"
    fi
}

# Function to create directories
create_directories() {
    print_section "Creating Directories"
    
    local directories
    directories=("$LOG_DIR" "$REPORT_DIR" "$BACKUP_DIR")
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir" 2>/dev/null; then
                print_result "OK" "Created directory: $dir"
            else
                print_result "WARNING" "Could not create directory: $dir (may need sudo)"
            fi
        else
            print_result "OK" "Directory exists: $dir"
        fi
    done
}

# Function to run hardware health check
run_hardware_check() {
    print_section "Hardware Health Check"
    
    local hardware_script
    hardware_script="$SCRIPT_DIR/../health-checks/check-hardware.sh"
    
    if [[ -f "$hardware_script" ]]; then
        if [[ -x "$hardware_script" ]]; then
            print_result "OK" "Running hardware health check..."
            if "$hardware_script"; then
                print_result "OK" "Hardware health check completed successfully"
            else
                local exit_code=$?
                if [[ $exit_code -eq 2 ]]; then
                    print_result "WARNING" "Hardware health check completed with warnings"
                else
                    print_result "ERROR" "Hardware health check failed"
                fi
            fi
        else
            print_result "WARNING" "Hardware script not executable, making it executable..."
            if chmod +x "$hardware_script"; then
                run_hardware_check
            else
                print_result "ERROR" "Could not make hardware script executable"
            fi
        fi
    else
        print_result "ERROR" "Hardware health check script not found: $hardware_script"
    fi
}

# Function to run configuration health check
run_configuration_check() {
    print_section "Configuration Health Check"
    
    local config_script
    config_script="$SCRIPT_DIR/../health-checks/check-configuration.sh"
    
    if [[ -f "$config_script" ]]; then
        if [[ -x "$config_script" ]]; then
            print_result "OK" "Running configuration health check..."
            if "$config_script"; then
                print_result "OK" "Configuration health check completed successfully"
            else
                local exit_code=$?
                if [[ $exit_code -eq 2 ]]; then
                    print_result "WARNING" "Configuration health check completed with warnings"
                else
                    print_result "ERROR" "Configuration health check failed"
                fi
            fi
        else
            print_result "WARNING" "Configuration script not executable, making it executable..."
            if chmod +x "$config_script"; then
                run_configuration_check
            else
                print_result "ERROR" "Could not make configuration script executable"
            fi
        fi
    else
        print_result "ERROR" "Configuration health check script not found: $config_script"
    fi
}

# Function to run Kubernetes health check
run_kubernetes_check() {
    print_section "Kubernetes Components Health Check"
    
    local k8s_script
    k8s_script="$SCRIPT_DIR/../health-checks/check-kubernetes.sh"
    
    if [[ -f "$k8s_script" ]]; then
        if [[ -x "$k8s_script" ]]; then
            print_result "OK" "Running Kubernetes health check..."
            if "$k8s_script"; then
                print_result "OK" "Kubernetes health check completed successfully"
            else
                local exit_code=$?
                if [[ $exit_code -eq 2 ]]; then
                    print_result "WARNING" "Kubernetes health check completed with warnings"
                else
                    print_result "ERROR" "Kubernetes health check failed"
                fi
            fi
        else
            print_result "WARNING" "Kubernetes script not executable, making it executable..."
            if chmod +x "$k8s_script"; then
                run_kubernetes_check
            else
                print_result "ERROR" "Could not make Kubernetes script executable"
            fi
        fi
    else
        print_result "ERROR" "Kubernetes health check script not found: $k8s_script"
    fi
}

# Function to run etcd backup
run_etcd_backup() {
    print_section "etcd Backup"
    
    local backup_script
    backup_script="$SCRIPT_DIR/../backup/backup-etcd.sh"
    
    if [[ -f "$backup_script" ]]; then
        if [[ -x "$backup_script" ]]; then
            print_result "OK" "Running etcd backup..."
            if "$backup_script"; then
                print_result "OK" "etcd backup completed successfully"
            else
                local exit_code=$?
                if [[ $exit_code -eq 2 ]]; then
                    print_result "WARNING" "etcd backup completed with warnings"
                else
                    print_result "ERROR" "etcd backup failed"
                fi
            fi
        else
            print_result "WARNING" "Backup script not executable, making it executable..."
            if chmod +x "$backup_script"; then
                run_etcd_backup
            else
                print_result "ERROR" "Could not make backup script executable"
            fi
        fi
    else
        print_result "ERROR" "etcd backup script not found: $backup_script"
    fi
}

# Function to collect logs
collect_logs() {
    print_section "Log Collection"
    
    local log_collection_dir
    log_collection_dir="$LOG_DIR/logs-$(date +%Y%m%d-%H%M%S)"
    
    if mkdir -p "$log_collection_dir"; then
        print_result "OK" "Created log collection directory: $log_collection_dir"
        
        # Collect system logs
        if command_exists "journalctl"; then
            print_result "OK" "Collecting system logs..."
            journalctl --since "24 hours ago" > "$log_collection_dir/system.log" 2>/dev/null || true
            journalctl -u kubelet --since "24 hours ago" > "$log_collection_dir/kubelet.log" 2>/dev/null || true
            journalctl -u docker --since "24 hours ago" > "$log_collection_dir/docker.log" 2>/dev/null || true
            journalctl -u containerd --since "24 hours ago" > "$log_collection_dir/containerd.log" 2>/dev/null || true
        fi
        
        # Collect Kubernetes logs
        if command_exists "kubectl"; then
            print_result "OK" "Collecting Kubernetes logs..."
            kubectl get events --all-namespaces --sort-by='.lastTimestamp' > "$log_collection_dir/k8s-events.log" 2>/dev/null || true
            kubectl get pods --all-namespaces -o wide > "$log_collection_dir/k8s-pods.log" 2>/dev/null || true
            kubectl get nodes -o wide > "$log_collection_dir/k8s-nodes.log" 2>/dev/null || true
        fi
        
        # Collect etcd logs
        if command_exists "etcdctl"; then
            print_result "OK" "Collecting etcd information..."
            etcdctl member list > "$log_collection_dir/etcd-members.log" 2>/dev/null || true
            etcdctl endpoint health > "$log_collection_dir/etcd-health.log" 2>/dev/null || true
        fi
        
        # Collect system information
        print_result "OK" "Collecting system information..."
        uname -a > "$log_collection_dir/system-info.log" 2>/dev/null || true
        cat /etc/os-release > "$log_collection_dir/os-info.log" 2>/dev/null || true
        free -h > "$log_collection_dir/memory-info.log" 2>/dev/null || true
        df -h > "$log_collection_dir/disk-info.log" 2>/dev/null || true
        ip addr > "$log_collection_dir/network-info.log" 2>/dev/null || true
        
        print_result "OK" "Log collection completed: $log_collection_dir"
    else
        print_result "ERROR" "Failed to create log collection directory"
    fi
}

# Function to generate comprehensive report
generate_report() {
    print_section "Generating Comprehensive Report"
    
    local report_file
    report_file="$REPORT_DIR/cluster-health-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# Kubernetes Cluster Health Report

**Generated:** $(date)  
**Node:** $(hostname)  
**Script:** $0  

## Executive Summary

This report provides a comprehensive overview of the Kubernetes cluster health status.

## System Information

- **Hostname:** $(hostname)
- **OS:** $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null || echo "Unknown")
- **Kernel:** $(uname -r)
- **Architecture:** $(uname -m)

## Health Check Results

### Hardware Health
$(if [[ -f "$LOG_DIR/hardware-health-check-$(date +%Y%m%d)*.log" ]]; then
    echo "Hardware health check log available"
    echo "Summary:"
    grep -E "(PASS|WARNING|ERROR):" "$LOG_DIR"/hardware-health-check-$(date +%Y%m%d)*.log | tail -10 || echo "No results found"
else
    echo "Hardware health check not performed or log not found"
fi)

### Configuration Health
$(if [[ -f "$LOG_DIR/config-health-check-$(date +%Y%m%d)*.log" ]]; then
    echo "Configuration health check log available"
    echo "Summary:"
    grep -E "(PASS|WARNING|ERROR):" "$LOG_DIR"/config-health-check-$(date +%Y%m%d)*.log | tail -10 || echo "No results found"
else
    echo "Configuration health check not performed or log not found"
fi)

### Kubernetes Health
$(if [[ -f "$LOG_DIR/kubernetes-health-check-$(date +%Y%m%d)*.log" ]]; then
    echo "Kubernetes health check log available"
    echo "Summary:"
    grep -E "(PASS|WARNING|ERROR):" "$LOG_DIR"/kubernetes-health-check-$(date +%Y%m%d)*.log | tail -10 || echo "No results found"
else
    echo "Kubernetes health check not performed or log not found"
fi)

## Backup Status

$(if [[ -d "$BACKUP_DIR" ]]; then
    echo "### etcd Backups"
    echo "Backup directory: $BACKUP_DIR"
    echo ""
    echo "Recent backups:"
    find "$BACKUP_DIR" -name "etcd-backup-*.db*" -type f -exec ls -lh {} \; 2>/dev/null | head -5 || echo "No backups found"
else
    echo "Backup directory not found: $BACKUP_DIR"
fi)

## Recommendations

Based on the health check results, consider the following actions:

1. **Immediate Actions:**
   - Address any ERROR level issues
   - Review WARNING level issues for potential problems

2. **Maintenance Actions:**
   - Regular health checks
   - Backup verification
   - Log rotation and cleanup

3. **Monitoring:**
   - Set up automated health checks
   - Configure alerting for critical issues
   - Monitor resource usage trends

## Log Files

- **Main log:** $LOG_FILE
- **Hardware check:** $LOG_DIR/hardware-health-check-*.log
- **Configuration check:** $LOG_DIR/config-health-check-*.log
- **Kubernetes check:** $LOG_DIR/kubernetes-health-check-*.log
- **etcd backup:** $LOG_DIR/etcd-backup-*.log

## Next Steps

1. Review all log files for detailed information
2. Address any critical issues identified
3. Schedule regular health checks
4. Update documentation based on findings

---
*Report generated by Kubernetes Troubleshooting Toolbox*
EOF
    
    print_result "OK" "Comprehensive report generated: $report_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMANDS]"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -v, --verbose            Enable verbose output"
    echo "  -q, --quiet              Suppress output (errors only)"
    echo "  -l, --log-dir DIR        Log directory (default: $LOG_DIR)"
    echo "  -b, --backup-dir DIR     Backup directory (default: $BACKUP_DIR)"
    echo "  -r, --report-dir DIR     Report directory (default: $REPORT_DIR)"
    echo ""
    echo "Commands:"
    echo "  all                      Run all checks and maintenance tasks (default)"
    echo "  hardware                 Run hardware health check only"
    echo "  config                   Run configuration health check only"
    echo "  kubernetes               Run Kubernetes health check only"
    echo "  backup                   Run etcd backup only"
    echo "  logs                     Collect logs only"
    echo "  report                   Generate report only"
    echo ""
    echo "Examples:"
    echo "  $0                       # Run all checks"
    echo "  $0 hardware             # Run hardware check only"
    echo "  $0 -v backup            # Run backup with verbose output"
    echo "  $0 -l /custom/logs all  # Run all checks with custom log directory"
}

# Function to run specific command
run_command() {
    local command="$1"
    
    case "$command" in
        "hardware")
            run_hardware_check
            ;;
        "config")
            run_configuration_check
            ;;
        "kubernetes")
            run_kubernetes_check
            ;;
        "backup")
            run_etcd_backup
            ;;
        "logs")
            collect_logs
            ;;
        "report")
            generate_report
            ;;
        "all"|"")
            run_hardware_check
            run_configuration_check
            run_kubernetes_check
            run_etcd_backup
            collect_logs
            generate_report
            ;;
        *)
            echo "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Parse command line arguments
    local command="all"
    local verbose=false
    local quiet=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -l|--log-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            -b|--backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -r|--report-dir)
                REPORT_DIR="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                command="$1"
                shift
                ;;
        esac
    done
    
    # Set up logging
    LOG_FILE="$LOG_DIR/toolbox-$(date +%Y%m%d-%H%M%S).log"
    
    # Print header
    if [[ "$quiet" != "true" ]]; then
        print_header
    fi
    
    # Create directories
    create_directories
    
    # Run the specified command
    run_command "$command"
    
    # Print summary
    if [[ "$quiet" != "true" ]]; then
        echo -e "\n${PURPLE}=== Summary ===${NC}"
        echo "Troubleshooting completed at: $(date)"
        echo "Log file: $LOG_FILE"
        echo "Report directory: $REPORT_DIR"
        
    # Count results from log
    local success_count
    success_count=$(grep -c "SUCCESS:" "$LOG_FILE" 2>/dev/null || echo "0")
    local warning_count
    warning_count=$(grep -c "WARNING:" "$LOG_FILE" 2>/dev/null || echo "0")
    local error_count
    error_count=$(grep -c "ERROR:" "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo "Results: $success_count successful, $warning_count warnings, $error_count errors"
    
    if [[ "$error_count" -gt 0 ]]; then
        echo -e "${RED}Some errors were encountered. Please review the logs.${NC}"
        exit 1
    elif [[ "$warning_count" -gt 0 ]]; then
        echo -e "${YELLOW}Some warnings were encountered. Please review the logs.${NC}"
        exit 2
    else
        echo -e "${GREEN}All checks completed successfully!${NC}"
        exit 0
    fi
    fi
}

# Run main function
main "$@" 