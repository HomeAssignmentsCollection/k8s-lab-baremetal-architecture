#!/bin/bash

# etcd Backup Script for Kubernetes Cluster
# This script creates backups of the etcd database

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="/var/backups/etcd"
ETCD_CERT_DIR="/etc/kubernetes/pki/etcd"
ETCD_ENDPOINTS="https://127.0.0.1:2379"
BACKUP_RETENTION_DAYS=30
COMPRESS_BACKUP=true

# Log file
LOG_FILE="/tmp/etcd-backup-$(date +%Y%m%d-%H%M%S).log"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Function to check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_result "ERROR" "This script must be run as root"
        exit 1
    fi
    
    # Check if etcdctl exists
    if ! command_exists "etcdctl"; then
        print_result "ERROR" "etcdctl command not found"
        exit 1
    fi
    
    # Check if backup directory exists
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_result "WARNING" "Backup directory does not exist: $BACKUP_DIR"
        if mkdir -p "$BACKUP_DIR"; then
            print_result "OK" "Created backup directory: $BACKUP_DIR"
        else
            print_result "ERROR" "Failed to create backup directory: $BACKUP_DIR"
            exit 1
        fi
    else
        print_result "OK" "Backup directory exists: $BACKUP_DIR"
    fi
    
    # Check etcd certificates
    local cert_files
    cert_files=(
        "$ETCD_CERT_DIR/ca.crt"
        "$ETCD_CERT_DIR/server.crt"
        "$ETCD_CERT_DIR/server.key"
    )
    
    for cert_file in "${cert_files[@]}"; do
        if [[ -f "$cert_file" ]]; then
            print_result "OK" "Certificate file exists: $cert_file"
        else
            print_result "WARNING" "Certificate file not found: $cert_file"
        fi
    done
}

# Function to check etcd health
check_etcd_health() {
    print_section "Checking etcd Health"
    
    # Check etcd endpoint health
    if etcdctl --endpoints="$ETCD_ENDPOINTS" \
        --cacert="$ETCD_CERT_DIR/ca.crt" \
        --cert="$ETCD_CERT_DIR/server.crt" \
        --key="$ETCD_CERT_DIR/server.key" \
        endpoint health >/dev/null 2>&1; then
        print_result "OK" "etcd endpoint is healthy"
    else
        print_result "ERROR" "etcd endpoint is not healthy"
        return 1
    fi
    
    # Get etcd cluster info
    local cluster_info
    cluster_info=$(etcdctl --endpoints="$ETCD_ENDPOINTS" \
        --cacert="$ETCD_CERT_DIR/ca.crt" \
        --cert="$ETCD_CERT_DIR/server.crt" \
        --key="$ETCD_CERT_DIR/server.key" \
        member list 2>/dev/null || echo "")
    
    if [[ -n "$cluster_info" ]]; then
        print_result "OK" "etcd cluster members:"
        echo "$cluster_info" | while read -r member_line; do
            echo "  - $member_line"
        done
    else
        print_result "WARNING" "Could not retrieve etcd cluster info"
    fi
}

# Function to create etcd backup
create_etcd_backup() {
    print_section "Creating etcd Backup"
    
    # Generate backup filename
    local backup_timestamp
    backup_timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_filename
    backup_filename="etcd-backup-${backup_timestamp}.db"
    local backup_path
    backup_path="$BACKUP_DIR/$backup_filename"
    
    # Create backup
    log_message "INFO" "Starting etcd backup to: $backup_path"
    
    if etcdctl --endpoints="$ETCD_ENDPOINTS" \
        --cacert="$ETCD_CERT_DIR/ca.crt" \
        --cert="$ETCD_CERT_DIR/server.crt" \
        --key="$ETCD_CERT_DIR/server.key" \
        snapshot save "$backup_path" >/dev/null 2>&1; then
        print_result "OK" "etcd backup created successfully: $backup_filename"
        
        # Get backup file size
        local backup_size
        backup_size=$(du -h "$backup_path" | cut -f1)
        print_result "OK" "Backup size: $backup_size"
        
        # Verify backup
        if etcdctl snapshot status "$backup_path" >/dev/null 2>&1; then
            print_result "OK" "Backup verification successful"
        else
            print_result "ERROR" "Backup verification failed"
            return 1
        fi
        
        # Compress backup if enabled
        if [[ "$COMPRESS_BACKUP" == "true" ]]; then
            local compressed_backup_path
            compressed_backup_path="${backup_path}.gz"
            
            if gzip "$backup_path"; then
                print_result "OK" "Backup compressed: ${backup_filename}.gz"
                
                # Get compressed size
                local compressed_size
                compressed_size=$(du -h "$compressed_backup_path" | cut -f1)
                print_result "OK" "Compressed backup size: $compressed_size"
            else
                print_result "WARNING" "Failed to compress backup"
            fi
        fi
        
        # Create backup metadata
        local metadata_file
        metadata_file="${backup_path%.*}.metadata"
        cat > "$metadata_file" << EOF
Backup created: $(date)
etcd version: $(etcdctl version | head -1)
Backup file: $backup_filename
Backup size: $backup_size
Compressed: $COMPRESS_BACKUP
Cluster endpoints: $ETCD_ENDPOINTS
EOF
        
        print_result "OK" "Backup metadata created: $(basename "$metadata_file")"
        
    else
        print_result "ERROR" "Failed to create etcd backup"
        return 1
    fi
}

# Function to clean old backups
clean_old_backups() {
    print_section "Cleaning Old Backups"
    
    # Find old backup files
    local old_backups
    old_backups=$(find "$BACKUP_DIR" -name "etcd-backup-*.db*" -mtime +$BACKUP_RETENTION_DAYS 2>/dev/null || echo "")
    
    if [[ -n "$old_backups" ]]; then
        local backup_count
        backup_count=$(echo "$old_backups" | wc -l)
        print_result "INFO" "Found $backup_count old backup(s) to remove"
        
        echo "$old_backups" | while read -r old_backup; do
            if rm -f "$old_backup"; then
                print_result "OK" "Removed old backup: $(basename "$old_backup")"
            else
                print_result "WARNING" "Failed to remove old backup: $(basename "$old_backup")"
            fi
        done
    else
        print_result "OK" "No old backups to remove"
    fi
}

# Function to list existing backups
list_existing_backups() {
    print_section "Existing Backups"
    
    local existing_backups
    existing_backups=$(find "$BACKUP_DIR" -name "etcd-backup-*.db*" -type f 2>/dev/null | sort || echo "")
    
    if [[ -n "$existing_backups" ]]; then
        local backup_count
        backup_count=$(echo "$existing_backups" | wc -l)
        print_result "OK" "Found $backup_count existing backup(s):"
        
        echo "$existing_backups" | while read -r backup_file; do
            local file_size
            file_size=$(du -h "$backup_file" | cut -f1)
            local file_date
            file_date=$(stat -c %y "$backup_file" | cut -d' ' -f1)
            print_result "INFO" "  $(basename "$backup_file") - $file_size - $file_date"
        done
    else
        print_result "INFO" "No existing backups found"
    fi
}

# Function to test backup restoration (dry run)
test_backup_restoration() {
    print_section "Testing Backup Restoration"
    
    # Find the most recent backup
    local latest_backup
    latest_backup=$(find "$BACKUP_DIR" -name "etcd-backup-*.db" -type f 2>/dev/null | sort | tail -1 || echo "")
    
    if [[ -n "$latest_backup" ]]; then
        print_result "INFO" "Testing restoration of: $(basename "$latest_backup")"
        
        # Create temporary directory for test
        local temp_dir
        temp_dir=$(mktemp -d)
        
        if etcdctl snapshot restore "$latest_backup" --data-dir="$temp_dir" >/dev/null 2>&1; then
            print_result "OK" "Backup restoration test successful"
            
            # Check restored data
            local restored_keys
            restored_keys=$(etcdctl --data-dir="$temp_dir" get --prefix="" --keys-only | wc -l || echo "0")
            print_result "OK" "Restored backup contains $restored_keys keys"
        else
            print_result "ERROR" "Backup restoration test failed"
        fi
        
        # Clean up temporary directory
        rm -rf "$temp_dir"
    else
        print_result "WARNING" "No backup files found for restoration test"
    fi
}

# Function to create backup report
create_backup_report() {
    print_section "Creating Backup Report"
    
    local report_file
    report_file="$BACKUP_DIR/backup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
etcd Backup Report
=================
Generated: $(date)
Backup directory: $BACKUP_DIR
etcd endpoints: $ETCD_ENDPOINTS
Compression enabled: $COMPRESS_BACKUP
Retention days: $BACKUP_RETENTION_DAYS

Backup Summary:
$(find "$BACKUP_DIR" -name "etcd-backup-*.db*" -type f 2>/dev/null | sort | while read -r backup; do
    echo "- $(basename "$backup") ($(du -h "$backup" | cut -f1)) - $(stat -c %y "$backup")"
done)

System Information:
- etcd version: $(etcdctl version | head -1)
- etcd health: $(etcdctl --endpoints="$ETCD_ENDPOINTS" --cacert="$ETCD_CERT_DIR/ca.crt" --cert="$ETCD_CERT_DIR/server.crt" --key="$ETCD_CERT_DIR/server.key" endpoint health 2>/dev/null | head -1 || echo "Unknown")

Log file: $LOG_FILE
EOF
    
    print_result "OK" "Backup report created: $(basename "$report_file")"
}

# Main function
main() {
    echo -e "${BLUE}etcd Backup Script for Kubernetes Cluster${NC}"
    echo "Started at: $(date)"
    echo "Log file: $LOG_FILE"
    echo "Backup directory: $BACKUP_DIR"
    
    # Run all functions
    check_prerequisites
    check_etcd_health
    list_existing_backups
    create_etcd_backup
    test_backup_restoration
    clean_old_backups
    create_backup_report
    
    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo "etcd backup completed at: $(date)"
    echo "Log file: $LOG_FILE"
    
    # Count results from log
    local success_count
    success_count=$(grep -c "SUCCESS:" "$LOG_FILE" || echo "0")
    local warning_count
    warning_count=$(grep -c "WARNING:" "$LOG_FILE" || echo "0")
    local error_count
    error_count=$(grep -c "ERROR:" "$LOG_FILE" || echo "0")
    
    echo "Results: $success_count successful, $warning_count warnings, $error_count errors"
    
    if [[ "$error_count" -gt 0 ]]; then
        exit 1
    elif [[ "$warning_count" -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --backup-dir DIR     Backup directory (default: $BACKUP_DIR)"
    echo "  -e, --endpoints ENDPOINTS etcd endpoints (default: $ETCD_ENDPOINTS)"
    echo "  -r, --retention DAYS     Backup retention days (default: $BACKUP_RETENTION_DAYS)"
    echo "  -c, --compress           Compress backups (default: $COMPRESS_BACKUP)"
    echo "  -n, --no-compress        Do not compress backups"
    echo "  -l, --list-only          List existing backups only"
    echo "  -t, --test-only          Test backup restoration only"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Create backup with default settings"
    echo "  $0 -d /backups/etcd      # Use custom backup directory"
    echo "  $0 -r 7                  # Keep backups for 7 days"
    echo "  $0 -l                    # List existing backups only"
    echo "  $0 -t                    # Test backup restoration only"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -e|--endpoints)
            ETCD_ENDPOINTS="$2"
            shift 2
            ;;
        -r|--retention)
            BACKUP_RETENTION_DAYS="$2"
            shift 2
            ;;
        -c|--compress)
            COMPRESS_BACKUP=true
            shift
            ;;
        -n|--no-compress)
            COMPRESS_BACKUP=false
            shift
            ;;
        -l|--list-only)
            list_existing_backups
            exit 0
            ;;
        -t|--test-only)
            test_backup_restoration
            exit 0
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@" 