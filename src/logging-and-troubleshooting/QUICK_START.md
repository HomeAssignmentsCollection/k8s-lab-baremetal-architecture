# Quick Start Guide - Logging and Troubleshooting Module

## 🚀 Quick Commands

### 1. Complete Health Check (Recommended)
```bash
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh
```

### 2. Individual Health Checks
```bash
# Hardware check only
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh hardware

# Configuration check only  
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh config

# Kubernetes components check only
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh kubernetes
```

### 3. Maintenance Tasks
```bash
# Create etcd backup
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh backup

# Collect logs
sudo src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh logs

# Generate report
src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh report
```

## 📋 What Each Check Does

### Hardware Check
- ✅ CPU usage and load average
- ✅ Memory and swap usage  
- ✅ Disk space and inode usage
- ✅ Network interface status
- ✅ System temperature
- ✅ Hardware errors in dmesg

### Configuration Check
- ✅ Kubernetes config files
- ✅ System kernel parameters
- ✅ Container runtime settings
- ✅ Network configuration
- ✅ Security settings (AppArmor, SELinux)
- ✅ Time synchronization

### Kubernetes Check
- ✅ Cluster connectivity
- ✅ Node status and health
- ✅ Control plane components
- ✅ Worker node components
- ✅ Network policies and CNI
- ✅ Storage components
- ✅ Recent error events

## 📊 Understanding Results

### Exit Codes
- **0** = All checks passed ✅
- **1** = Critical errors found ❌
- **2** = Warnings found ⚠️

### Output Colors
- 🟢 **Green** = OK/Passed
- 🟡 **Yellow** = Warning
- 🔴 **Red** = Error

## 📁 Generated Files

### Logs
- `/tmp/k8s-troubleshooting/toolbox-*.log` - Main execution log
- `/tmp/k8s-troubleshooting/hardware-health-check-*.log` - Hardware check results
- `/tmp/k8s-troubleshooting/config-health-check-*.log` - Configuration check results
- `/tmp/k8s-troubleshooting/kubernetes-health-check-*.log` - Kubernetes check results

### Reports
- `/tmp/k8s-reports/cluster-health-report-*.md` - Comprehensive health report
- `/var/backups/etcd/etcd-backup-*.db` - etcd backup files

## 🔧 Troubleshooting Common Issues

### Permission Denied
```bash
chmod +x src/logging-and-troubleshooting/scripts/*.sh
chmod +x src/logging-and-troubleshooting/health-checks/*.sh
chmod +x src/logging-and-troubleshooting/backup/*.sh
```

### Missing Tools
```bash
# Ubuntu/Debian
sudo apt install sysstat bc jq

# CentOS/RHEL  
sudo yum install sysstat bc jq
```

### etcd Backup Fails
```bash
# Check etcd health
etcdctl endpoint health

# Verify certificates exist
ls -la /etc/kubernetes/pki/etcd/
```

## 📖 Next Steps

1. **Read the full documentation**: `src/logging-and-troubleshooting/README.md`
2. **Review methodology**: `src/logging-and-troubleshooting/methodology/`
3. **Set up automated monitoring**: Schedule regular health checks
4. **Configure alerts**: Set up notifications for critical issues

## 🆘 Need Help?

- Check the generated log files for detailed error information
- Review the comprehensive README.md file
- Ensure all prerequisites are met
- Run individual checks to isolate specific issues 