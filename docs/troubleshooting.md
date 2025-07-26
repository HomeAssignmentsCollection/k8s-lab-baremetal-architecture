# Troubleshooting Guide / Руководство по устранению неполадок

[English](#english) | [Русский](#russian)

## English

### Common Issues and Solutions

#### 1. Network Connectivity Issues

**Problem**: Cannot connect to Kubernetes API server
```
Error: The connection to the server localhost:8080 was refused
```

**Solutions**:
- Check if kubelet is running: `systemctl status kubelet`
- Verify API server is listening: `netstat -tlnp | grep 6443`
- Check firewall rules: `ufw status` or `firewall-cmd --list-all`
- Verify load balancer configuration

**Problem**: DNS resolution issues
```
Error: cannot resolve kubernetes.default.svc.cluster.local
```

**Solutions**:
- Check CoreDNS pods: `kubectl get pods -n kube-system | grep coredns`
- Verify CoreDNS service: `kubectl get svc -n kube-system | grep coredns`
- Check CoreDNS logs: `kubectl logs -n kube-system deployment/coredns`

#### 2. Node Issues

**Problem**: Nodes not joining the cluster
```
Error: failed to join cluster: timeout waiting for the condition
```

**Solutions**:
- Check kubelet logs: `journalctl -u kubelet -f`
- Verify join token is valid: `kubeadm token list`
- Check network connectivity between nodes
- Verify container runtime is working

**Problem**: Nodes showing NotReady status
```
NAME     STATUS     ROLES    AGE   VERSION
node-1   NotReady   worker   5m    v1.28.0
```

**Solutions**:
- Check kubelet status: `systemctl status kubelet`
- Verify CNI plugin is installed: `ls /opt/cni/bin/`
- Check CNI configuration: `ls /etc/cni/net.d/`
- Review kubelet logs: `journalctl -u kubelet -f`

#### 3. Pod Issues

**Problem**: Pods stuck in Pending state
```
NAME    READY   STATUS    RESTARTS   AGE
pod-1   0/1     Pending   0          10m
```

**Solutions**:
- Check node resources: `kubectl describe node`
- Verify storage classes: `kubectl get storageclass`
- Check pod events: `kubectl describe pod <pod-name>`
- Verify image pull policy and registry access

**Problem**: Pods in CrashLoopBackOff
```
NAME    READY   STATUS             RESTARTS   AGE
pod-1   0/1     CrashLoopBackOff   5          2m
```

**Solutions**:
- Check pod logs: `kubectl logs <pod-name>`
- Verify application configuration
- Check resource limits and requests
- Review application health checks

#### 4. Storage Issues

**Problem**: PersistentVolumeClaims not binding
```
NAME   STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-1  Pending                                      local-storage  5m
```

**Solutions**:
- Check storage classes: `kubectl get storageclass`
- Verify storage provisioner is running
- Check storage capacity and availability
- Review PVC configuration

#### 5. Security Issues

**Problem**: RBAC permission denied
```
Error: pods is forbidden: User "system:serviceaccount:default:default" cannot get resource "pods"
```

**Solutions**:
- Check RBAC policies: `kubectl get clusterrolebinding`
- Verify service account permissions
- Review role and rolebinding configurations
- Check namespace policies

### Diagnostic Commands

#### Cluster Information
```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes -o wide

# Get system pods
kubectl get pods -n kube-system

# Get events
kubectl get events --sort-by='.lastTimestamp'
```

#### Network Diagnostics
```bash
# Check DNS resolution
nslookup kubernetes.default.svc.cluster.local

# Test pod-to-pod connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local

# Check network policies
kubectl get networkpolicies --all-namespaces
```

#### Storage Diagnostics
```bash
# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv

# Check persistent volume claims
kubectl get pvc --all-namespaces
```

#### Log Analysis
```bash
# Kubelet logs
journalctl -u kubelet -f

# API server logs
kubectl logs -n kube-system kube-apiserver-<node-name>

# Controller manager logs
kubectl logs -n kube-system kube-controller-manager-<node-name>

# Scheduler logs
kubectl logs -n kube-system kube-scheduler-<node-name>
```

## Русский

### Частые проблемы и решения

#### 1. Проблемы сетевой связности

**Проблема**: Не удается подключиться к API серверу Kubernetes
```
Ошибка: The connection to the server localhost:8080 was refused
```

**Решения**:
- Проверьте, запущен ли kubelet: `systemctl status kubelet`
- Убедитесь, что API сервер слушает: `netstat -tlnp | grep 6443`
- Проверьте правила файрвола: `ufw status` или `firewall-cmd --list-all`
- Убедитесь в правильности конфигурации балансировщика нагрузки

**Проблема**: Проблемы с DNS разрешением
```
Ошибка: cannot resolve kubernetes.default.svc.cluster.local
```

**Решения**:
- Проверьте поды CoreDNS: `kubectl get pods -n kube-system | grep coredns`
- Убедитесь в работе сервиса CoreDNS: `kubectl get svc -n kube-system | grep coredns`
- Проверьте логи CoreDNS: `kubectl logs -n kube-system deployment/coredns`

#### 2. Проблемы с узлами

**Проблема**: Узлы не присоединяются к кластеру
```
Ошибка: failed to join cluster: timeout waiting for the condition
```

**Решения**:
- Проверьте логи kubelet: `journalctl -u kubelet -f`
- Убедитесь в валидности join токена: `kubeadm token list`
- Проверьте сетевую связность между узлами
- Убедитесь в работе container runtime

**Проблема**: Узлы показывают статус NotReady
```
NAME     STATUS     ROLES    AGE   VERSION
node-1   NotReady   worker   5m    v1.28.0
```

**Решения**:
- Проверьте статус kubelet: `systemctl status kubelet`
- Убедитесь в установке CNI плагина: `ls /opt/cni/bin/`
- Проверьте конфигурацию CNI: `ls /etc/cni/net.d/`
- Просмотрите логи kubelet: `journalctl -u kubelet -f`

#### 3. Проблемы с подами

**Проблема**: Поды застряли в состоянии Pending
```
NAME    READY   STATUS    RESTARTS   AGE
pod-1   0/1     Pending   0          10m
```

**Решения**:
- Проверьте ресурсы узлов: `kubectl describe node`
- Убедитесь в наличии storage classes: `kubectl get storageclass`
- Проверьте события пода: `kubectl describe pod <pod-name>`
- Убедитесь в правильности image pull policy и доступе к registry

**Проблема**: Поды в состоянии CrashLoopBackOff
```
NAME    READY   STATUS             RESTARTS   AGE
pod-1   0/1     CrashLoopBackOff   5          2m
```

**Решения**:
- Проверьте логи пода: `kubectl logs <pod-name>`
- Убедитесь в правильности конфигурации приложения
- Проверьте лимиты и запросы ресурсов
- Просмотрите health checks приложения

### Команды диагностики

#### Информация о кластере
```bash
# Получить информацию о кластере
kubectl cluster-info

# Получить узлы
kubectl get nodes -o wide

# Получить системные поды
kubectl get pods -n kube-system

# Получить события
kubectl get events --sort-by='.lastTimestamp'
```

#### Сетевая диагностика
```bash
# Проверить DNS разрешение
nslookup kubernetes.default.svc.cluster.local

# Протестировать связность между подами
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local

# Проверить сетевые политики
kubectl get networkpolicies --all-namespaces
```

### Полезные ресурсы

- [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug/)
- [Kubernetes Debugging](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/)
- [Kubernetes Logging](https://kubernetes.io/docs/concepts/cluster-administration/logging/) 