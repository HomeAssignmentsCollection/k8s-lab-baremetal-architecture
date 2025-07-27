#!/bin/bash

# Hardware Health Check Script for Kubernetes Nodes
# This script checks hardware resources on both master and worker nodes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
THRESHOLD_CPU_USAGE=80
THRESHOLD_MEMORY_USAGE=85
THRESHOLD_DISK_USAGE=85
THRESHOLD_INODE_USAGE=85

# Log file
LOG_FILE="/tmp/hardware-health-check-$(date +%Y%m%d-%H%M%S).log"

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
    log_message "INFO" "Starting check: $1"
}

# Function to print result
print_result() {
    local status="$1"
    local message="$2"
    if [[ "$status" == "OK" ]]; then
        echo -e "${GREEN}✓ $message${NC}"
        log_message "INFO" "PASS: $message"
    elif [[ "$status" == "WARNING" ]]; then
        echo -e "${YELLOW}⚠ $message${NC}"
        log_message "WARNING" "$message"
    else
        echo -e "${RED}✗ $message${NC}"
        log_message "ERROR" "$message"
    fi
}

# Function to check CPU usage
check_cpu_usage() {
    print_section "CPU Usage Check"
    
    if command_exists "mpstat"; then
        local cpu_usage
        cpu_usage=$(mpstat 1 1 | awk 'NR==4 {print 100-$NF}')
        cpu_usage=${cpu_usage%.*}
        
        if [[ "$cpu_usage" -lt "$THRESHOLD_CPU_USAGE" ]]; then
            print_result "OK" "CPU usage: ${cpu_usage}% (threshold: ${THRESHOLD_CPU_USAGE}%)"
        else
            print_result "WARNING" "CPU usage: ${cpu_usage}% (threshold: ${THRESHOLD_CPU_USAGE}%)"
        fi
        
        # Check CPU load average
        local load_avg
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        local cpu_cores
        cpu_cores=$(nproc)
        local load_per_core
        load_per_core=$(echo "scale=2; $load_avg / $cpu_cores" | bc)
        
        if (( $(echo "$load_per_core < 1.0" | bc -l) )); then
            print_result "OK" "Load average per core: ${load_per_core} (1 min)"
        else
            print_result "WARNING" "Load average per core: ${load_per_core} (1 min)"
        fi
    else
        print_result "ERROR" "mpstat command not found"
    fi
}

# Function to check memory usage
check_memory_usage() {
    print_section "Memory Usage Check"
    
    if command_exists "free"; then
        local mem_info
        mem_info=$(free -m)
        local total_mem
        total_mem=$(echo "$mem_info" | awk 'NR==2{print $2}')
        local used_mem
        used_mem=$(echo "$mem_info" | awk 'NR==2{print $3}')
        local mem_usage
        mem_usage=$((used_mem * 100 / total_mem))
        
        if [[ "$mem_usage" -lt "$THRESHOLD_MEMORY_USAGE" ]]; then
            print_result "OK" "Memory usage: ${mem_usage}% (${used_mem}MB/${total_mem}MB)"
        else
            print_result "WARNING" "Memory usage: ${mem_usage}% (${used_mem}MB/${total_mem}MB)"
        fi
        
        # Check swap usage
        local swap_info
        swap_info=$(echo "$mem_info" | awk 'NR==3{print $2, $3}')
        local total_swap
        total_swap=$(echo "$swap_info" | awk '{print $1}')
        local used_swap
        used_swap=$(echo "$swap_info" | awk '{print $2}')
        
        if [[ "$total_swap" -gt 0 ]]; then
            local swap_usage
            swap_usage=$((used_swap * 100 / total_swap))
            if [[ "$swap_usage" -lt 50 ]]; then
                print_result "OK" "Swap usage: ${swap_usage}% (${used_swap}MB/${total_swap}MB)"
            else
                print_result "WARNING" "Swap usage: ${swap_usage}% (${used_swap}MB/${total_swap}MB)"
            fi
        else
            print_result "OK" "No swap configured"
        fi
    else
        print_result "ERROR" "free command not found"
    fi
}

# Function to check disk usage
check_disk_usage() {
    print_section "Disk Usage Check"
    
    if command_exists "df"; then
        # Check all mounted filesystems
        df -h | grep -E '^/dev/' | while read -r line; do
            local mount_point
            mount_point=$(echo "$line" | awk '{print $6}')
            local usage_percent
            usage_percent=$(echo "$line" | awk '{print $5}' | sed 's/%//')
            local total_size
            total_size=$(echo "$line" | awk '{print $2}')
            local used_size
            used_size=$(echo "$line" | awk '{print $3}')
            
            if [[ "$usage_percent" -lt "$THRESHOLD_DISK_USAGE" ]]; then
                print_result "OK" "Disk usage for $mount_point: ${usage_percent}% (${used_size}/${total_size})"
            else
                print_result "WARNING" "Disk usage for $mount_point: ${usage_percent}% (${used_size}/${total_size})"
            fi
        done
        
        # Check inode usage
        df -i | grep -E '^/dev/' | while read -r line; do
            local mount_point
            mount_point=$(echo "$line" | awk '{print $6}')
            local inode_usage
            inode_usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
            
            if [[ "$inode_usage" -lt "$THRESHOLD_INODE_USAGE" ]]; then
                print_result "OK" "Inode usage for $mount_point: ${inode_usage}%"
            else
                print_result "WARNING" "Inode usage for $mount_point: ${inode_usage}%"
            fi
        done
    else
        print_result "ERROR" "df command not found"
    fi
}

# Function to check network interfaces
check_network_interfaces() {
    print_section "Network Interfaces Check"
    
    if command_exists "ip"; then
        # Check network interfaces status
        ip link show | grep -E '^[0-9]+:' | while read -r line; do
            local interface
            interface=$(echo "$line" | awk -F': ' '{print $2}' | awk '{print $1}')
            local state
            state=$(echo "$line" | grep -o 'state [A-Z]\+' | awk '{print $2}')
            
            if [[ "$state" == "UP" ]]; then
                print_result "OK" "Interface $interface is UP"
            else
                print_result "WARNING" "Interface $interface is $state"
            fi
        done
        
        # Check for network errors
        if command_exists "netstat"; then
            local network_errors
            network_errors=$(netstat -i | awk 'NR>2 {sum+=$5+$6+$8+$9} END {print sum}')
            if [[ "$network_errors" -eq 0 ]]; then
                print_result "OK" "No network interface errors detected"
            else
                print_result "WARNING" "Network interface errors detected: $network_errors"
            fi
        fi
    else
        print_result "ERROR" "ip command not found"
    fi
}

# Function to check system temperature (if available)
check_system_temperature() {
    print_section "System Temperature Check"
    
    # Check for thermal zones
    if [[ -d "/sys/class/thermal" ]]; then
        local thermal_zones
        thermal_zones=$(find /sys/class/thermal/thermal_zone*/ -name "temp" 2>/dev/null | head -5)
        
        if [[ -n "$thermal_zones" ]]; then
            echo "$thermal_zones" | while read -r temp_file; do
                local zone_name
                zone_name=$(basename "$(dirname "$temp_file")")
                local temp_raw
                temp_raw=$(cat "$temp_file" 2>/dev/null || echo "0")
                local temp_celsius
                temp_celsius=$((temp_raw / 1000))
                
                if [[ "$temp_celsius" -lt 80 ]]; then
                    print_result "OK" "Temperature $zone_name: ${temp_celsius}°C"
                else
                    print_result "WARNING" "Temperature $zone_name: ${temp_celsius}°C"
                fi
            done
        else
            print_result "INFO" "No thermal sensors found"
        fi
    else
        print_result "INFO" "Thermal monitoring not available"
    fi
}

# Function to check system uptime
check_system_uptime() {
    print_section "System Uptime Check"
    
    if command_exists "uptime"; then
        local uptime_info
        uptime_info=$(uptime)
        local uptime_days
        uptime_days=$(echo "$uptime_info" | grep -o 'up [0-9]\+ days' | awk '{print $2}' || echo "0")
        
        if [[ "$uptime_days" -gt 30 ]]; then
            print_result "WARNING" "System uptime: $uptime_days days (consider reboot for updates)"
        else
            print_result "OK" "System uptime: $uptime_days days"
        fi
        
        echo "$uptime_info"
    else
        print_result "ERROR" "uptime command not found"
    fi
}

# Function to check for hardware errors
check_hardware_errors() {
    print_section "Hardware Errors Check"
    
    # Check dmesg for hardware errors
    local hardware_errors
    hardware_errors=$(dmesg | grep -i -E "(error|fail|critical|hardware)" | tail -10)
    
    if [[ -n "$hardware_errors" ]]; then
        print_result "WARNING" "Hardware errors detected in dmesg:"
        echo "$hardware_errors" | while read -r error; do
            echo "  - $error"
        done
    else
        print_result "OK" "No hardware errors detected in dmesg"
    fi
    
    # Check for failed systemd units
    if command_exists "systemctl"; then
        local failed_units
        failed_units=$(systemctl --failed --no-legend --no-pager 2>/dev/null | grep -v "0 loaded units listed" || true)
        
        if [[ -n "$failed_units" ]]; then
            print_result "WARNING" "Failed systemd units detected:"
            echo "$failed_units" | while read -r unit; do
                echo "  - $unit"
            done
        else
            print_result "OK" "No failed systemd units"
        fi
    fi
}

# Main function
main() {
    echo -e "${BLUE}Hardware Health Check for Kubernetes Node${NC}"
    echo "Started at: $(date)"
    echo "Log file: $LOG_FILE"
    
    # Check if running as root (optional)
    if [[ $EUID -eq 0 ]]; then
        log_message "INFO" "Running as root user"
    else
        log_message "WARNING" "Not running as root - some checks may be limited"
    fi
    
    # Run all checks
    check_system_uptime
    check_cpu_usage
    check_memory_usage
    check_disk_usage
    check_network_interfaces
    check_system_temperature
    check_hardware_errors
    
    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo "Hardware health check completed at: $(date)"
    echo "Log file: $LOG_FILE"
    
    # Count results from log
    local pass_count
    pass_count=$(grep -c "PASS:" "$LOG_FILE" || echo "0")
    local warning_count
    warning_count=$(grep -c "WARNING:" "$LOG_FILE" || echo "0")
    local error_count
    error_count=$(grep -c "ERROR:" "$LOG_FILE" || echo "0")
    
    echo "Results: $pass_count passed, $warning_count warnings, $error_count errors"
    
    if [[ "$error_count" -gt 0 ]]; then
        exit 1
    elif [[ "$warning_count" -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

# Run main function
main "$@" 