# Конкретные исправления и улучшения - Kubernetes Baremetal Lab

## 🔧 Исправления безопасности

### 1. Jenkins - Удаление хардкода паролей

**Файл:** `src/kubernetes/jenkins/jenkins-deployment.yaml`

**Проблема:** Хардкод паролей в конфигурации
```yaml
# Текущий код (проблемный)
users:
  - id: "admin"
    password: "admin"
```

**Решение:** Использовать Kubernetes Secrets
```yaml
# Новый код
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-admin-secret
  namespace: jenkins
type: Opaque
data:
  admin-password: <base64-encoded-password>
---
# В ConfigMap
securityRealm:
  local:
    allowsSignup: false
    users:
      - id: "admin"
        password: "${JENKINS_ADMIN_PASSWORD}"
```

### 2. Terraform - Добавление валидации переменных

**Файл:** `src/terraform/variables.tf`

**Добавить валидацию:**
```hcl
variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.28.0"
  
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.Y.Z"
  }
}

variable "control_plane_ips" {
  description = "List of control plane node IP addresses"
  type        = list(string)
  default     = ["192.168.1.10", "192.168.1.11", "192.168.1.12"]
  
  validation {
    condition     = length(var.control_plane_ips) >= 1
    error_message = "At least one control plane IP must be specified"
  }
}
```

### 3. Ansible - Улучшение безопасности SSH

**Файл:** `src/ansible/playbooks/prepare-systems.yml`

**Заменить lineinfile на template:**
```yaml
# Создать файл templates/sshd_config.j2
- name: Configure SSH with template
  template:
    src: templates/sshd_config.j2
    dest: /etc/ssh/sshd_config
    mode: '0600'
    validate: 'sshd -t -f %s'
  notify: restart ssh
```

**Содержимое `templates/sshd_config.j2`:**
```
# SSH Configuration for Kubernetes nodes
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Security settings
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Performance settings
ClientAliveInterval 60
ClientAliveCountMax 3
TCPKeepAlive yes
```

## 🚀 Улучшения производительности

### 1. Добавление HPA для Prometheus

**Файл:** `src/kubernetes/monitoring/prometheus/prometheus-hpa.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: prometheus-hpa
  namespace: monitoring
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: prometheus
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
```

### 2. Улучшение Node Affinity для Jenkins

**Файл:** `src/kubernetes/jenkins/jenkins-deployment.yaml`

```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-type
                operator: In
                values:
                - big
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - jenkins
              topologyKey: kubernetes.io/hostname
```

## 🛡️ Улучшения безопасности

### 1. Добавление Pod Security Policies

**Файл:** `src/kubernetes/security/pod-security/pod-security-policies.yaml`

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-psp
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'runtime/default'
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  readOnlyRootFilesystem: true
```

### 2. Улучшение Network Policies

**Файл:** `src/kubernetes/security/network-policies/enhanced-network-policies.yaml`

```yaml
# Deny all egress by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: lab-stands
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  # Allow Kubernetes API
  - to: []
    ports:
    - protocol: TCP
      port: 443
  # Allow specific services
  - to:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
```

## 📊 Улучшения мониторинга

### 1. Добавление Alertmanager конфигурации

**Файл:** `src/kubernetes/monitoring/alertmanager/alertmanager-config.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      resolve_timeout: 5m
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'slack-notifications'
      routes:
      - match:
          severity: critical
        receiver: 'pager-duty-critical'
        continue: true
    
    receivers:
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#alerts'
        title: '{{ template "slack.title" . }}'
        text: '{{ template "slack.text" . }}'
    
    - name: 'pager-duty-critical'
      pagerduty_configs:
      - routing_key: YOUR_PAGERDUTY_KEY
```

### 2. Добавление Grafana Dashboards

**Файл:** `src/kubernetes/monitoring/grafana/dashboards/cluster-overview.json`

```json
{
  "dashboard": {
    "id": null,
    "title": "Kubernetes Cluster Overview",
    "tags": ["kubernetes", "cluster"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Cluster CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{container!=\"\"}[5m])) by (pod)",
            "legendFormat": "{{pod}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Cluster Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(container_memory_usage_bytes{container!=\"\"}) by (pod)",
            "legendFormat": "{{pod}}"
          }
        ]
      }
    ]
  }
}
```

## 🔄 Улучшения CI/CD

### 1. Добавление GitHub Actions

**Файл:** `.github/workflows/ci.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Terraform Format Check
      run: terraform fmt -check -recursive
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Setup Ansible
      run: |
        sudo apt-get update
        sudo apt-get install -y ansible ansible-lint
    
    - name: Ansible Lint
      run: ansible-lint src/ansible/playbooks/
    
    - name: Shell Check
      run: |
        sudo apt-get install -y shellcheck
        find . -name "*.sh" -exec shellcheck {} \;
    
    - name: YAML Lint
      run: |
        pip install yamllint
        yamllint -c .yamllint .

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Kind
      uses: helm/kind-action@v1.7.0
      with:
        node_image: kindest/node:v1.28.0
    
    - name: Deploy to Kind
      run: |
        kubectl apply -f src/kubernetes/namespaces/
        kubectl apply -f src/kubernetes/monitoring/
        kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
    
    - name: Run Tests
      run: |
        # Add your test commands here
        echo "Running tests..."

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
```

### 2. Добавление Pre-commit hooks

**Файл:** `.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: check-case-conflict
      - id: check-executables-have-shebangs

  - repo: https://github.com/terraform-docs/terraform-docs
    rev: v0.16.0
    hooks:
      - id: terraform_docs
        args: ['--sort-by-required']

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint

  - repo: https://github.com/ansible/ansible-lint
    rev: v6.22.1
    hooks:
      - id: ansible-lint

  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck
        args: ['--severity=warning']
```

## 📝 Улучшения документации

### 1. Добавление API документации

**Файл:** `docs/api-reference.md`

```markdown
# API Reference

## Terraform Variables

### Infrastructure Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `control_plane_ips` | `list(string)` | `["192.168.1.10", "192.168.1.11", "192.168.1.12"]` | List of control plane node IP addresses |
| `worker_ips` | `list(string)` | `["192.168.1.20", "192.168.1.21", "192.168.1.22"]` | List of worker node IP addresses |
| `kubernetes_version` | `string` | `"1.28.0"` | Kubernetes version to install |

### Security Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_rbac` | `bool` | `true` | Enable RBAC for Kubernetes |
| `enable_network_policies` | `bool` | `true` | Enable network policies |

## Ansible Variables

### System Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `kubernetes_version` | `string` | `"1.28.0"` | Kubernetes version to install |
| `container_runtime` | `string` | `"containerd"` | Container runtime to use |

## Kubernetes Resources

### Namespaces

- `monitoring`: Prometheus, Grafana, Alertmanager
- `jenkins`: CI/CD components
- `gitops`: ArgoCD and GitOps tools
- `artifacts`: Artifact management
- `lab-stands`: Example applications
```

### 2. Добавление Troubleshooting Guide

**Файл:** `docs/troubleshooting.md`

```markdown
# Troubleshooting Guide

## Common Issues

### 1. Kubernetes Nodes Not Ready

**Symptoms:**
- Nodes show `NotReady` status
- Pods cannot be scheduled

**Diagnosis:**
```bash
kubectl get nodes
kubectl describe node <node-name>
kubectl logs -n kube-system kubelet-<node-name>
```

**Solutions:**
1. Check if kubelet is running: `systemctl status kubelet`
2. Verify container runtime: `systemctl status containerd`
3. Check disk space: `df -h`
4. Verify network connectivity

### 2. Prometheus Cannot Scrape Targets

**Symptoms:**
- Targets show as `DOWN` in Prometheus UI
- No metrics being collected

**Diagnosis:**
```bash
kubectl get pods -n monitoring
kubectl logs -n monitoring prometheus-<pod-name>
kubectl get endpoints -n monitoring
```

**Solutions:**
1. Check if targets are accessible
2. Verify RBAC permissions
3. Check network policies
4. Verify service endpoints

### 3. Jenkins Cannot Start

**Symptoms:**
- Jenkins pod in `CrashLoopBackOff`
- Cannot access Jenkins UI

**Diagnosis:**
```bash
kubectl get pods -n jenkins
kubectl logs -n jenkins jenkins-<pod-name>
kubectl describe pod -n jenkins jenkins-<pod-name>
```

**Solutions:**
1. Check resource limits
2. Verify persistent volume
3. Check node affinity
4. Verify secrets configuration
```

## 🎯 Приоритеты внедрения

### Высокий приоритет (1-2 недели)
1. ✅ Исправления безопасности Jenkins
2. ✅ Добавление валидации Terraform
3. ✅ Улучшение SSH конфигурации
4. ✅ Добавление HPA для Prometheus

### Средний приоритет (2-4 недели)
1. ✅ Добавление Pod Security Policies
2. ✅ Улучшение Network Policies
3. ✅ Настройка Alertmanager
4. ✅ Добавление CI/CD pipeline

### Низкий приоритет (1-2 месяца)
1. ✅ Добавление Grafana dashboards
2. ✅ Улучшение документации
3. ✅ Добавление monitoring dashboards
4. ✅ Оптимизация производительности

---

*Этот файл содержит конкретные исправления и улучшения, выявленные в ходе код ревью. Рекомендуется внедрять изменения поэтапно, начиная с критических проблем безопасности.* 