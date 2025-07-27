# Kubernetes Logging and Troubleshooting Module

This module provides comprehensive tools and methodologies for logging, monitoring, and troubleshooting Kubernetes clusters in baremetal environments.

## Overview

The logging and troubleshooting module is designed to help operators maintain healthy Kubernetes clusters by providing:

- **Systematic troubleshooting methodologies**
- **Comprehensive health check scripts**
- **Automated backup procedures**
- **Log collection and analysis tools**
- **Maintenance automation**

## Module Structure

```
src/logging-and-troubleshooting/
├── methodology/
│   ├── troubleshooting-methodology.md    # Systematic troubleshooting approach
│   └── logging-strategy.md               # Logging strategy and best practices
├── health-checks/
│   ├── check-hardware.sh                 # Hardware health check script
│   ├── check-configuration.sh            # Configuration health check script
│   └── check-kubernetes.sh               # Kubernetes components health check
├── backup/
│   └── backup-etcd.sh                    # etcd backup and restore script
├── scripts/
│   └── cluster-troubleshooting-toolbox.sh # Main orchestration script
└── README.md                             # This file
```

## Quick Start

### 1. Run Complete Health Check

```bash
# Make scripts executable
chmod +x src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh
chmod +x src/logging-and-troubleshooting/health-checks/*.sh
chmod +x src/logging-and-troubleshooting/backup/*.sh

# Run all health checks and maintenance tasks
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh
```

### 2. Run Individual Checks

```bash
# Hardware health check only
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh hardware

# Configuration health check only
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh config

# Kubernetes components health check only
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh kubernetes

# etcd backup only
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh backup
```

### 3. Collect Logs and Generate Report

```bash
# Collect logs only
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh logs

# Generate comprehensive report
src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh report
```

## Components

### 1. Methodology Documentation

#### Troubleshooting Methodology (`methodology/troubleshooting-methodology.md`)

Provides a systematic approach to troubleshooting Kubernetes cluster issues:

- **Information Gathering Phase**: Collect relevant data about the issue
- **Problem Classification**: Categorize issues by type (hardware, network, configuration, etc.)
- **Root Cause Analysis**: Use structured approaches to identify root causes
- **Common Issues and Solutions**: Reference guide for frequent problems
- **Emergency Procedures**: Step-by-step procedures for critical situations

#### Logging Strategy (`methodology/logging-strategy.md`)

Defines comprehensive logging strategy for Kubernetes clusters:

- **Log Sources**: Control plane, nodes, applications, infrastructure
- **Log Collection Methods**: Container logs, system logs, application logs
- **Log Processing Pipeline**: Collection, processing, storage, analysis
- **Log Retention Policy**: Short-term, medium-term, long-term retention
- **Security and Compliance**: Log security and regulatory requirements

### 2. Health Check Scripts

#### Hardware Health Check (`health-checks/check-hardware.sh`)

Comprehensive hardware resource monitoring:

- **CPU Usage**: Current usage, load average, per-core metrics
- **Memory Usage**: RAM usage, swap usage, memory pressure
- **Disk Usage**: Filesystem usage, inode usage, disk performance
- **Network Interfaces**: Interface status, network errors, connectivity
- **System Temperature**: Thermal monitoring (if available)
- **System Uptime**: Uptime monitoring and reboot recommendations
- **Hardware Errors**: dmesg analysis, failed systemd units

#### Configuration Health Check (`health-checks/check-configuration.sh`)

Validates system and Kubernetes configuration:

- **Kubernetes Configuration Files**: kubelet, kubeadm, admin.conf
- **System Configuration**: Kernel parameters, systemd services
- **Container Runtime Configuration**: Docker/containerd settings
- **Network Configuration**: CNI, iptables, DNS settings
- **Security Configuration**: AppArmor, SELinux, firewall status
- **Storage Configuration**: Required directories, storage classes
- **Time Synchronization**: NTP, chrony status

#### Kubernetes Components Health Check (`health-checks/check-kubernetes.sh`)

Monitors Kubernetes cluster components:

- **Kubectl Connectivity**: API server connectivity and health
- **Node Status**: All nodes status, roles, readiness
- **Control Plane Components**: API server, controller manager, scheduler, etcd
- **Worker Components**: Kubelet, container runtime, kube-proxy
- **Namespaces and Quotas**: Default namespaces, resource quotas
- **Network Policies**: Network policies, CNI pods
- **Storage Components**: Storage classes, CSI drivers
- **Recent Events**: Error events, warnings, critical issues

### 3. Backup Scripts

#### etcd Backup (`backup/backup-etcd.sh`)

Automated etcd backup and restore procedures:

- **Prerequisites Check**: Root access, etcdctl, certificates
- **etcd Health Check**: Endpoint health, cluster membership
- **Backup Creation**: Snapshot creation with verification
- **Backup Compression**: Optional gzip compression
- **Backup Metadata**: Timestamp, version, size information
- **Old Backup Cleanup**: Automatic retention management
- **Restoration Testing**: Dry-run restoration verification

### 4. Main Toolbox Script

#### Cluster Troubleshooting Toolbox (`scripts/cluster-troubleshooting-toolbox.sh`)

Orchestrates all health checks and maintenance tasks:

- **Directory Management**: Creates necessary directories
- **Script Orchestration**: Runs individual health checks
- **Log Collection**: Automated log gathering
- **Report Generation**: Comprehensive health reports
- **Error Handling**: Proper exit codes and error reporting

## Usage Examples

### Regular Health Monitoring

```bash
# Daily health check
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh

# Weekly comprehensive check with verbose output
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh -v all
```

### Troubleshooting Specific Issues

```bash
# Check hardware when experiencing performance issues
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh hardware

# Check configuration after system changes
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh config

# Check Kubernetes components when pods are failing
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh kubernetes
```

### Maintenance Tasks

```bash
# Create etcd backup before upgrades
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh backup

# Collect logs for analysis
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh logs

# Generate report for stakeholders
src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh report
```

### Custom Configuration

```bash
# Use custom directories
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh \
  -l /custom/logs \
  -b /custom/backups \
  -r /custom/reports \
  all

# Quiet mode for automated scripts
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh -q all
```

## Output and Logging

### Log Files

All scripts generate detailed logs in the configured log directory:

- **Main toolbox log**: `toolbox-YYYYMMDD-HHMMSS.log`
- **Hardware check log**: `hardware-health-check-YYYYMMDD-HHMMSS.log`
- **Configuration check log**: `config-health-check-YYYYMMDD-HHMMSS.log`
- **Kubernetes check log**: `kubernetes-health-check-YYYYMMDD-HHMMSS.log`
- **etcd backup log**: `etcd-backup-YYYYMMDD-HHMMSS.log`

### Reports

Comprehensive reports are generated in Markdown format:

- **Health reports**: `cluster-health-report-YYYYMMDD-HHMMSS.md`
- **Backup reports**: `backup-report-YYYYMMDD-HHMMSS.txt`

### Exit Codes

- **0**: All checks passed successfully
- **1**: Critical errors encountered
- **2**: Warnings encountered (non-critical)

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+, CentOS 8+, RHEL 8+)
- **Kubernetes**: 1.20+ (for newer features)
- **Root Access**: Required for most checks and backups
- **Network Connectivity**: Required for cluster communication

### Required Tools

- **kubectl**: Kubernetes command-line tool
- **etcdctl**: etcd command-line tool
- **systemctl**: Systemd service management
- **journalctl**: System log access
- **Standard Unix tools**: grep, awk, sed, find, etc.

### Optional Tools

- **mpstat**: CPU statistics (sysstat package)
- **bc**: Basic calculator for calculations
- **jq**: JSON processor for configuration parsing
- **gzip**: Compression for backups

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd k8s-lab-baremetal-architecture
```

### 2. Make Scripts Executable

```bash
chmod +x src/logging-and-troubleshooting/scripts/*.sh
chmod +x src/logging-and-troubleshooting/health-checks/*.sh
chmod +x src/logging-and-troubleshooting/backup/*.sh
```

### 3. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install sysstat bc jq

# CentOS/RHEL
sudo yum install sysstat bc jq
```

### 4. Configure Directories

```bash
# Create backup directory (if not exists)
sudo mkdir -p /var/backups/etcd

# Set appropriate permissions
sudo chown root:root /var/backups/etcd
sudo chmod 700 /var/backups/etcd
```

## Best Practices

### 1. Regular Monitoring

- **Daily**: Quick health checks
- **Weekly**: Comprehensive health checks
- **Monthly**: Full backup and restore testing

### 2. Log Management

- **Rotation**: Implement log rotation to prevent disk space issues
- **Retention**: Follow the defined retention policy
- **Analysis**: Regular review of logs for patterns and trends

### 3. Backup Strategy

- **Frequency**: Daily backups for production clusters
- **Retention**: 30 days for regular backups, 1 year for monthly backups
- **Testing**: Regular restore testing to verify backup integrity
- **Offsite**: Consider offsite backup storage for disaster recovery

### 4. Security Considerations

- **Access Control**: Restrict access to backup files and logs
- **Encryption**: Encrypt sensitive backup data
- **Audit Trail**: Maintain audit logs for all operations

### 5. Automation

- **Cron Jobs**: Schedule regular health checks
- **Monitoring Integration**: Integrate with existing monitoring systems
- **Alerting**: Set up alerts for critical issues

## Troubleshooting

### Common Issues

#### Permission Denied Errors

```bash
# Ensure scripts are executable
chmod +x src/logging-and-troubleshooting/scripts/*.sh

# Run with sudo for system-level checks
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh
```

#### etcd Backup Failures

```bash
# Check etcd health
etcdctl endpoint health

# Verify certificates
ls -la /etc/kubernetes/pki/etcd/

# Check etcd service status
systemctl status etcd
```

#### Kubernetes Connectivity Issues

```bash
# Check kubectl configuration
kubectl config view

# Verify API server
kubectl cluster-info

# Check node connectivity
ping <master-node-ip>
```

### Getting Help

1. **Check Logs**: Review the generated log files for detailed error information
2. **Review Documentation**: Consult the methodology documents for troubleshooting approaches
3. **Verify Prerequisites**: Ensure all required tools and permissions are in place
4. **Test Individual Components**: Run individual health checks to isolate issues

## Contributing

When contributing to this module:

1. **Follow Scripting Standards**: Use the established patterns and conventions
2. **Add Documentation**: Update README and methodology documents
3. **Test Thoroughly**: Test scripts on different environments
4. **Handle Errors Gracefully**: Implement proper error handling and exit codes
5. **Maintain Compatibility**: Ensure compatibility with supported Kubernetes versions

## License

This module is part of the Kubernetes Baremetal Lab project and follows the same licensing terms. 