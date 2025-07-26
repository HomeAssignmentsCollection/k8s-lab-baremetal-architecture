# Configuration Guide / Руководство по конфигурации

[English](#english) | [Русский](#russian)

## English

This guide explains how to configure the Kubernetes Baremetal Lab project for different environments and use cases.

## Quick Start Configuration

### 1. Generate Environment Configuration

```bash
# Generate configuration for development environment
./configs/scripts/generate-config.sh dev

# Generate configuration for staging environment
./configs/scripts/generate-config.sh staging

# Generate configuration for production environment
./configs/scripts/generate-config.sh prod
```

### 2. Customize Configuration

Edit the generated files in `configs/environments/<environment>/`:

- `terraform.tfvars` - Infrastructure configuration
- `secrets.yaml` - Application secrets
- `kubernetes-config.yaml` - Application settings

### 3. Deploy with Configuration

```bash
# Deploy with YAML manifests
./src/scripts/deploy-all.sh

# Deploy with Helm charts
./src/scripts/deploy-helm.sh
```

## Configuration Structure

```
configs/
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars      # Infrastructure variables
│   │   ├── secrets.yaml          # Application secrets
│   │   └── kubernetes-config.yaml # Application configuration
│   ├── staging/
│   │   ├── terraform.tfvars
│   │   ├── secrets.yaml
│   │   └── kubernetes-config.yaml
│   └── prod/
│       ├── terraform.tfvars
│       ├── secrets.yaml
│       └── kubernetes-config.yaml
├── templates/
│   ├── terraform.tfvars.template
│   ├── secrets.template.yaml
│   └── kubernetes-config.template.yaml
├── validation/
│   └── schema.yaml
└── scripts/
    ├── generate-config.sh
    └── validate-config.sh
```

## Configuration Parameters

### Infrastructure Configuration (terraform.tfvars)

#### Network Configuration
```hcl
# Control plane node IPs
control_plane_ips = ["192.168.1.10", "192.168.1.11", "192.168.1.12"]

# Worker node IPs
worker_ips = ["192.168.1.20", "192.168.1.21", "192.168.1.22"]

# Load balancer IP
load_balancer_ip = "192.168.1.100"

# Network gateway
network_gateway = "192.168.1.1"

# DNS servers
dns_servers = ["8.8.8.8", "8.8.4.4"]
```

#### Kubernetes Configuration
```hcl
# Kubernetes version
kubernetes_version = "1.28.0"

# Container runtime
container_runtime = "containerd"

# CNI plugin
cni_plugin = "flannel"

# Pod CIDR
pod_cidr = "10.244.0.0/16"

# Service CIDR
service_cidr = "10.96.0.0/12"

# Cluster name
cluster_name = "baremetal-cluster"

# Cluster domain
cluster_domain = "cluster.local"
```

#### Security Configuration
```hcl
# Enable RBAC
enable_rbac = true

# Enable network policies
enable_network_policies = true

# Enable pod security policies
enable_pod_security_policies = false
```

#### Storage Configuration
```hcl
# Enable local storage
enable_local_storage = true

# Enable NFS storage
enable_nfs_storage = false

# NFS server (if enabled)
nfs_server = ""

# NFS path
nfs_path = "/exports"
```

### Application Configuration (kubernetes-config.yaml)

#### Jenkins Configuration
```yaml
jenkins:
  admin_user: "admin"
  num_executors: "2"
  jvm_opts: "-Xmx2g -Xms1g"
```

#### Grafana Configuration
```yaml
grafana:
  admin_user: "admin"
  allow_sign_up: "true"
  allow_anonymous: "false"
```

#### ArgoCD Configuration
```yaml
argocd:
  admin_user: "admin"
  repo_timeout: "180s"
  max_concurrent_reconciles: "1"
```

#### Monitoring Configuration
```yaml
prometheus:
  retention_days: "7"
  scrape_interval: "30s"

grafana:
  default_dashboard: "kubernetes-cluster"
```

### Secrets Configuration (secrets.yaml)

#### Application Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
type: Opaque
data:
  # Jenkins secrets
  jenkins-admin-password: <base64-encoded>
  jenkins-api-token: <base64-encoded>
  
  # Grafana secrets
  grafana-admin-password: <base64-encoded>
  grafana-secret-key: <base64-encoded>
  
  # ArgoCD secrets
  argocd-admin-password: <base64-encoded>
  argocd-server-secret: <base64-encoded>
  
  # Artifactory secrets
  artifactory-admin-password: <base64-encoded>
  artifactory-join-key: <base64-encoded>
```

## Environment-Specific Configurations

### Development Environment

#### Characteristics
- **Purpose**: Development and testing
- **Security**: Relaxed (simple passwords)
- **Resources**: Minimal
- **Access**: Open

#### Configuration
```yaml
# Development-specific settings
app.environment: "dev"
app.debug: "true"
app.log_level: "debug"

# Resource limits (lower for dev)
resources.jenkins.memory: "1Gi"
resources.jenkins.cpu: "500m"
resources.grafana.memory: "512Mi"
resources.grafana.cpu: "250m"

# Security (relaxed)
security.pod_security_policies: "false"
ingress.ssl_redirect: "false"
```

### Staging Environment

#### Characteristics
- **Purpose**: Pre-production testing
- **Security**: Moderate
- **Resources**: Medium
- **Access**: Limited

#### Configuration
```yaml
# Staging-specific settings
app.environment: "staging"
app.debug: "false"
app.log_level: "info"

# Resource limits (medium)
resources.jenkins.memory: "2Gi"
resources.jenkins.cpu: "1000m"
resources.grafana.memory: "1Gi"
resources.grafana.cpu: "500m"

# Security (moderate)
security.pod_security_policies: "true"
ingress.ssl_redirect: "true"
```

### Production Environment

#### Characteristics
- **Purpose**: Production workloads
- **Security**: Strict
- **Resources**: High
- **Access**: Restricted

#### Configuration
```yaml
# Production-specific settings
app.environment: "prod"
app.debug: "false"
app.log_level: "warn"

# Resource limits (high)
resources.jenkins.memory: "4Gi"
resources.jenkins.cpu: "2000m"
resources.grafana.memory: "2Gi"
resources.grafana.cpu: "1000m"

# Security (strict)
security.pod_security_policies: "true"
security.network_policies: "true"
ingress.ssl_redirect: "true"
```

## Advanced Configuration

### Custom Node Labels

```bash
# Label nodes by type
kubectl label nodes k8s-worker-big-01 node-type=big
kubectl label nodes k8s-worker-big-02 node-type=big
kubectl label nodes k8s-worker-big-03 node-type=big

kubectl label nodes k8s-worker-medium-01 node-type=medium
kubectl label nodes k8s-worker-medium-02 node-type=medium
kubectl label nodes k8s-worker-medium-03 node-type=medium

kubectl label nodes k8s-worker-small-01 node-type=small
kubectl label nodes k8s-worker-small-02 node-type=small
kubectl label nodes k8s-worker-small-03 node-type=small

# Label nodes by storage type
kubectl label nodes k8s-worker-big-01 storage-type=ssd
kubectl label nodes k8s-worker-big-02 storage-type=ssd
kubectl label nodes k8s-worker-big-03 storage-type=ssd

kubectl label nodes k8s-worker-medium-01 storage-type=hdd
kubectl label nodes k8s-worker-medium-02 storage-type=hdd
kubectl label nodes k8s-worker-medium-03 storage-type=hdd

# Apply taints for dedicated workloads
kubectl taint nodes k8s-worker-big-01 dedicated=jenkins:NoSchedule
kubectl taint nodes k8s-worker-big-02 dedicated=monitoring:NoSchedule
kubectl taint nodes k8s-worker-big-03 dedicated=artifacts:NoSchedule
```

### Custom Storage Classes

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: storage-type
    values:
    - ssd
```

### Custom Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: jenkins-network-policy
  namespace: jenkins
spec:
  podSelector:
    matchLabels:
      app: jenkins
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: gitops
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: artifacts
    ports:
    - protocol: TCP
      port: 8081
```

## Configuration Validation

### Validate Configuration Files

```bash
# Validate Terraform configuration
cd configs/environments/dev
terraform validate -var-file=terraform.tfvars

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('secrets.yaml'))"
python3 -c "import yaml; yaml.safe_load(open('kubernetes-config.yaml'))"

# Validate with custom script
./configs/scripts/validate-config.sh dev
```

### Validate Kubernetes Resources

```bash
# Validate manifests
kubectl apply --dry-run=client -f src/kubernetes/namespaces/all-namespaces.yaml
kubectl apply --dry-run=client -f src/kubernetes/storage/storage-classes.yaml

# Run test suite
./test/test-manifests.sh
```

## Troubleshooting Configuration

### Common Issues

#### 1. IP Address Conflicts
```bash
# Check for IP conflicts
nmap -sn 192.168.1.0/24

# Verify network configuration
ip addr show
```

#### 2. Storage Issues
```bash
# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv
kubectl get pvc --all-namespaces
```

#### 3. Network Issues
```bash
# Check network policies
kubectl get networkpolicy --all-namespaces

# Check service connectivity
kubectl get svc --all-namespaces
```

#### 4. Resource Issues
```bash
# Check node resources
kubectl describe nodes

# Check pod resource usage
kubectl top pods --all-namespaces
```

### Configuration Debugging

```bash
# Generate configuration with debug info
./configs/scripts/generate-config.sh dev --validate --debug

# Check configuration differences
diff configs/environments/dev/ configs/environments/staging/

# Validate configuration against schema
./configs/scripts/validate-config.sh dev --schema-validation
```

## Best Practices

### 1. Environment Separation
- Use separate configuration files for each environment
- Never use production secrets in development
- Use different resource limits per environment

### 2. Security
- Use strong passwords in production
- Enable RBAC and network policies
- Use secrets management for sensitive data

### 3. Resource Management
- Set appropriate resource limits
- Monitor resource usage
- Scale resources based on workload

### 4. Documentation
- Document all configuration changes
- Use version control for configuration
- Maintain configuration templates

## Русский

Это руководство объясняет, как настроить проект Kubernetes Baremetal Lab для различных окружений и случаев использования.

## Быстрый старт конфигурации

### 1. Генерация конфигурации окружения

```bash
# Генерация конфигурации для среды разработки
./configs/scripts/generate-config.sh dev

# Генерация конфигурации для staging окружения
./configs/scripts/generate-config.sh staging

# Генерация конфигурации для продакшен окружения
./configs/scripts/generate-config.sh prod
```

### 2. Настройка конфигурации

Отредактируйте сгенерированные файлы в `configs/environments/<environment>/`:

- `terraform.tfvars` - Конфигурация инфраструктуры
- `secrets.yaml` - Секреты приложений
- `kubernetes-config.yaml` - Настройки приложений

### 3. Развертывание с конфигурацией

```bash
# Развертывание с YAML манифестами
./src/scripts/deploy-all.sh

# Развертывание с Helm чартами
./src/scripts/deploy-helm.sh
```

## Структура конфигурации

```
configs/
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars      # Переменные инфраструктуры
│   │   ├── secrets.yaml          # Секреты приложений
│   │   └── kubernetes-config.yaml # Конфигурация приложений
│   ├── staging/
│   │   ├── terraform.tfvars
│   │   ├── secrets.yaml
│   │   └── kubernetes-config.yaml
│   └── prod/
│       ├── terraform.tfvars
│       ├── secrets.yaml
│       └── kubernetes-config.yaml
├── templates/
│   ├── terraform.tfvars.template
│   ├── secrets.template.yaml
│   └── kubernetes-config.template.yaml
├── validation/
│   └── schema.yaml
└── scripts/
    ├── generate-config.sh
    └── validate-config.sh
```

## Параметры конфигурации

### Конфигурация инфраструктуры (terraform.tfvars)

#### Сетевая конфигурация
```hcl
# IP адреса узлов control plane
control_plane_ips = ["192.168.1.10", "192.168.1.11", "192.168.1.12"]

# IP адреса worker узлов
worker_ips = ["192.168.1.20", "192.168.1.21", "192.168.1.22"]

# IP адрес load balancer
load_balancer_ip = "192.168.1.100"

# Сетевой шлюз
network_gateway = "192.168.1.1"

# DNS серверы
dns_servers = ["8.8.8.8", "8.8.4.4"]
```

#### Конфигурация Kubernetes
```hcl
# Версия Kubernetes
kubernetes_version = "1.28.0"

# Container runtime
container_runtime = "containerd"

# CNI плагин
cni_plugin = "flannel"

# CIDR подов
pod_cidr = "10.244.0.0/16"

# CIDR сервисов
service_cidr = "10.96.0.0/12"

# Имя кластера
cluster_name = "baremetal-cluster"

# Домен кластера
cluster_domain = "cluster.local"
```

#### Конфигурация безопасности
```hcl
# Включить RBAC
enable_rbac = true

# Включить сетевые политики
enable_network_policies = true

# Включить политики безопасности подов
enable_pod_security_policies = false
```

#### Конфигурация хранилища
```hcl
# Включить локальное хранилище
enable_local_storage = true

# Включить NFS хранилище
enable_nfs_storage = false

# NFS сервер (если включен)
nfs_server = ""

# NFS путь
nfs_path = "/exports"
```

### Конфигурация приложений (kubernetes-config.yaml)

#### Конфигурация Jenkins
```yaml
jenkins:
  admin_user: "admin"
  num_executors: "2"
  jvm_opts: "-Xmx2g -Xms1g"
```

#### Конфигурация Grafana
```yaml
grafana:
  admin_user: "admin"
  allow_sign_up: "true"
  allow_anonymous: "false"
```

#### Конфигурация ArgoCD
```yaml
argocd:
  admin_user: "admin"
  repo_timeout: "180s"
  max_concurrent_reconciles: "1"
```

#### Конфигурация мониторинга
```yaml
prometheus:
  retention_days: "7"
  scrape_interval: "30s"

grafana:
  default_dashboard: "kubernetes-cluster"
```

### Конфигурация секретов (secrets.yaml)

#### Секреты приложений
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
type: Opaque
data:
  # Секреты Jenkins
  jenkins-admin-password: <base64-encoded>
  jenkins-api-token: <base64-encoded>
  
  # Секреты Grafana
  grafana-admin-password: <base64-encoded>
  grafana-secret-key: <base64-encoded>
  
  # Секреты ArgoCD
  argocd-admin-password: <base64-encoded>
  argocd-server-secret: <base64-encoded>
  
  # Секреты Artifactory
  artifactory-admin-password: <base64-encoded>
  artifactory-join-key: <base64-encoded>
```

## Окружения-специфичные конфигурации

### Окружение разработки

#### Характеристики
- **Назначение**: Разработка и тестирование
- **Безопасность**: Расслабленная (простые пароли)
- **Ресурсы**: Минимальные
- **Доступ**: Открытый

#### Конфигурация
```yaml
# Настройки для разработки
app.environment: "dev"
app.debug: "true"
app.log_level: "debug"

# Лимиты ресурсов (ниже для dev)
resources.jenkins.memory: "1Gi"
resources.jenkins.cpu: "500m"
resources.grafana.memory: "512Mi"
resources.grafana.cpu: "250m"

# Безопасность (расслабленная)
security.pod_security_policies: "false"
ingress.ssl_redirect: "false"
```

### Staging окружение

#### Характеристики
- **Назначение**: Предпродакшенное тестирование
- **Безопасность**: Умеренная
- **Ресурсы**: Средние
- **Доступ**: Ограниченный

#### Конфигурация
```yaml
# Настройки для staging
app.environment: "staging"
app.debug: "false"
app.log_level: "info"

# Лимиты ресурсов (средние)
resources.jenkins.memory: "2Gi"
resources.jenkins.cpu: "1000m"
resources.grafana.memory: "1Gi"
resources.grafana.cpu: "500m"

# Безопасность (умеренная)
security.pod_security_policies: "true"
ingress.ssl_redirect: "true"
```

### Продакшен окружение

#### Характеристики
- **Назначение**: Продакшенные нагрузки
- **Безопасность**: Строгая
- **Ресурсы**: Высокие
- **Доступ**: Ограниченный

#### Конфигурация
```yaml
# Настройки для продакшена
app.environment: "prod"
app.debug: "false"
app.log_level: "warn"

# Лимиты ресурсов (высокие)
resources.jenkins.memory: "4Gi"
resources.jenkins.cpu: "2000m"
resources.grafana.memory: "2Gi"
resources.grafana.cpu: "1000m"

# Безопасность (строгая)
security.pod_security_policies: "true"
security.network_policies: "true"
ingress.ssl_redirect: "true"
```

## Продвинутая конфигурация

### Пользовательские метки узлов

```bash
# Маркировка узлов по типу
kubectl label nodes k8s-worker-big-01 node-type=big
kubectl label nodes k8s-worker-big-02 node-type=big
kubectl label nodes k8s-worker-big-03 node-type=big

kubectl label nodes k8s-worker-medium-01 node-type=medium
kubectl label nodes k8s-worker-medium-02 node-type=medium
kubectl label nodes k8s-worker-medium-03 node-type=medium

kubectl label nodes k8s-worker-small-01 node-type=small
kubectl label nodes k8s-worker-small-02 node-type=small
kubectl label nodes k8s-worker-small-03 node-type=small

# Маркировка узлов по типу хранилища
kubectl label nodes k8s-worker-big-01 storage-type=ssd
kubectl label nodes k8s-worker-big-02 storage-type=ssd
kubectl label nodes k8s-worker-big-03 storage-type=ssd

kubectl label nodes k8s-worker-medium-01 storage-type=hdd
kubectl label nodes k8s-worker-medium-02 storage-type=hdd
kubectl label nodes k8s-worker-medium-03 storage-type=hdd

# Применение taints для выделенных нагрузок
kubectl taint nodes k8s-worker-big-01 dedicated=jenkins:NoSchedule
kubectl taint nodes k8s-worker-big-02 dedicated=monitoring:NoSchedule
kubectl taint nodes k8s-worker-big-03 dedicated=artifacts:NoSchedule
```

### Пользовательские классы хранилищ

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: storage-type
    values:
    - ssd
```

### Пользовательские сетевые политики

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: jenkins-network-policy
  namespace: jenkins
spec:
  podSelector:
    matchLabels:
      app: jenkins
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: gitops
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: artifacts
    ports:
    - protocol: TCP
      port: 8081
```

## Валидация конфигурации

### Валидация файлов конфигурации

```bash
# Валидация конфигурации Terraform
cd configs/environments/dev
terraform validate -var-file=terraform.tfvars

# Валидация синтаксиса YAML
python3 -c "import yaml; yaml.safe_load(open('secrets.yaml'))"
python3 -c "import yaml; yaml.safe_load(open('kubernetes-config.yaml'))"

# Валидация с пользовательским скриптом
./configs/scripts/validate-config.sh dev
```

### Валидация ресурсов Kubernetes

```bash
# Валидация манифестов
kubectl apply --dry-run=client -f src/kubernetes/namespaces/all-namespaces.yaml
kubectl apply --dry-run=client -f src/kubernetes/storage/storage-classes.yaml

# Запуск тестового набора
./test/test-manifests.sh
```

## Устранение неполадок конфигурации

### Общие проблемы

#### 1. Конфликты IP адресов
```bash
# Проверка конфликтов IP
nmap -sn 192.168.1.0/24

# Проверка сетевой конфигурации
ip addr show
```

#### 2. Проблемы с хранилищем
```bash
# Проверка классов хранилищ
kubectl get storageclass

# Проверка persistent volumes
kubectl get pv
kubectl get pvc --all-namespaces
```

#### 3. Сетевые проблемы
```bash
# Проверка сетевых политик
kubectl get networkpolicy --all-namespaces

# Проверка подключения сервисов
kubectl get svc --all-namespaces
```

#### 4. Проблемы с ресурсами
```bash
# Проверка ресурсов узлов
kubectl describe nodes

# Проверка использования ресурсов подов
kubectl top pods --all-namespaces
```

### Отладка конфигурации

```bash
# Генерация конфигурации с отладочной информацией
./configs/scripts/generate-config.sh dev --validate --debug

# Проверка различий конфигурации
diff configs/environments/dev/ configs/environments/staging/

# Валидация конфигурации против схемы
./configs/scripts/validate-config.sh dev --schema-validation
```

## Лучшие практики

### 1. Разделение окружений
- Используйте отдельные файлы конфигурации для каждого окружения
- Никогда не используйте продакшен секреты в разработке
- Используйте разные лимиты ресурсов для каждого окружения

### 2. Безопасность
- Используйте сильные пароли в продакшене
- Включайте RBAC и сетевые политики
- Используйте управление секретами для чувствительных данных

### 3. Управление ресурсами
- Устанавливайте соответствующие лимиты ресурсов
- Мониторьте использование ресурсов
- Масштабируйте ресурсы на основе нагрузки

### 4. Документация
- Документируйте все изменения конфигурации
- Используйте контроль версий для конфигурации
- Поддерживайте шаблоны конфигурации 