# Kubernetes Cluster Troubleshooting Methodology

## Overview
This document outlines a systematic approach to troubleshooting Kubernetes cluster issues, from hardware problems to application-level failures.

## Troubleshooting Framework

### 1. Information Gathering Phase
- **Cluster Status**: Check overall cluster health
- **Node Status**: Verify all nodes are ready and healthy
- **Component Status**: Check control plane components
- **Resource Usage**: Monitor CPU, memory, disk, and network
- **Log Analysis**: Collect and analyze relevant logs

### 2. Problem Classification
- **Hardware Issues**: Physical problems with nodes
- **Network Issues**: Connectivity and routing problems
- **Configuration Issues**: Misconfigured components
- **Resource Issues**: Resource exhaustion
- **Application Issues**: Container and application problems

### 3. Root Cause Analysis
- **Top-Down Approach**: Start from symptoms, work down to root cause
- **Bottom-Up Approach**: Start from infrastructure, work up to symptoms
- **Elimination Method**: Systematically eliminate possible causes

## Diagnostic Commands Reference

### Cluster Health
```bash
# Overall cluster status
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Component status
kubectl get componentstatuses
kubectl get cs
```

### Node Diagnostics
```bash
# Node details
kubectl describe node <node-name>
kubectl get node <node-name> -o yaml

# Node resources
kubectl top nodes
kubectl describe node <node-name> | grep -A 10 "Allocated resources"
```

### Pod Diagnostics
```bash
# Pod status and details
kubectl get pods -o wide
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>

# Pod resources
kubectl top pods -n <namespace>
```

### Network Diagnostics
```bash
# Service connectivity
kubectl get svc -A
kubectl describe svc <service-name> -n <namespace>

# Network policies
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name> -n <namespace>
```

### Storage Diagnostics
```bash
# Persistent volumes
kubectl get pv
kubectl get pvc -A
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name> -n <namespace>
```

## Log Collection Strategy

### Control Plane Logs
- **kube-apiserver**: API server logs
- **kube-controller-manager**: Controller manager logs
- **kube-scheduler**: Scheduler logs
- **etcd**: Database logs

### Node Logs
- **kubelet**: Node agent logs
- **container runtime**: Docker/containerd logs
- **system logs**: Systemd and kernel logs

### Application Logs
- **Container logs**: Application-specific logs
- **Ingress logs**: Load balancer logs
- **Service mesh logs**: If using Istio/Linkerd

## Common Issues and Solutions

### Node Not Ready
1. Check kubelet status: `systemctl status kubelet`
2. Verify container runtime: `systemctl status docker` or `systemctl status containerd`
3. Check disk space: `df -h`
4. Verify network connectivity: `ping <master-node-ip>`

### Pod Stuck in Pending
1. Check node resources: `kubectl describe node`
2. Verify storage: `kubectl get pv,pvc`
3. Check taints/tolerations: `kubectl describe node | grep Taint`
4. Review events: `kubectl get events --sort-by='.lastTimestamp'`

### Service Connectivity Issues
1. Verify endpoints: `kubectl get endpoints -n <namespace>`
2. Check service configuration: `kubectl describe svc <service-name>`
3. Test connectivity: `kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup <service-name>`

### etcd Issues
1. Check etcd health: `etcdctl endpoint health`
2. Verify cluster membership: `etcdctl member list`
3. Check etcd logs: `journalctl -u etcd`

## Performance Troubleshooting

### Resource Bottlenecks
- **CPU**: Check CPU usage and limits
- **Memory**: Monitor memory usage and OOM events
- **Disk I/O**: Check disk performance and space
- **Network**: Monitor network bandwidth and latency

### Scaling Issues
- **Horizontal Pod Autoscaler**: Check HPA status and metrics
- **Cluster Autoscaler**: Verify node scaling decisions
- **Resource Quotas**: Check quota limits and usage

## Emergency Procedures

### Master Node Failure
1. Identify failed components
2. Check etcd cluster health
3. Restore from backup if necessary
4. Bring up replacement node

### Worker Node Failure
1. Drain the failing node
2. Check for data loss
3. Replace or repair the node
4. Verify workload redistribution

### etcd Corruption
1. Stop all control plane components
2. Restore etcd from backup
3. Restart control plane components
4. Verify cluster health

## Best Practices

### Preventive Measures
- Regular health checks
- Resource monitoring
- Log rotation and retention
- Backup procedures
- Documentation updates

### Response Procedures
- Follow runbooks
- Document all actions
- Communicate with stakeholders
- Post-incident analysis

### Tool Usage
- Use appropriate diagnostic tools
- Collect sufficient information
- Avoid destructive actions
- Test solutions in staging first 