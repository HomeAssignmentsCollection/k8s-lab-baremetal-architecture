# Configuration Directory / Директория конфигурации

[English](#english) | [Русский](#russian)

## English

This directory contains all configuration files and templates for the Kubernetes Baremetal Lab project.

## Directory Structure

```
configs/
├── environments/           # Environment-specific configurations
│   ├── dev/               # Development environment
│   │   ├── terraform.tfvars
│   │   ├── secrets.yaml
│   │   └── kubernetes-config.yaml
│   ├── staging/           # Staging environment
│   │   ├── terraform.tfvars
│   │   ├── secrets.yaml
│   │   └── kubernetes-config.yaml
│   └── prod/              # Production environment
│       ├── terraform.tfvars
│       ├── secrets.yaml
│       └── kubernetes-config.yaml
├── templates/             # Configuration templates
│   ├── kubernetes-config.template.yaml
│   └── secrets.template.yaml
├── validation/            # Configuration validation schemas
│   └── schema.yaml
├── scripts/               # Configuration management scripts
│   └── generate-config.sh
└── documentation/         # Configuration documentation
    ├── architecture-overview.md
    ├── configuration-guide.md
    └── installation-instructions.md
```

## Quick Start

### 1. Generate Configuration for Your Environment

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

- **terraform.tfvars**: Infrastructure configuration (IP addresses, network settings)
- **secrets.yaml**: Application secrets and passwords
- **kubernetes-config.yaml**: Application settings and resource limits

### 3. Validate Configuration

```bash
# Validate generated configuration
./configs/scripts/generate-config.sh dev --validate

# Dry run to see what would be generated
./configs/scripts/generate-config.sh dev --dry-run
```

## Network Architecture

### IP Address Ranges

| Network Segment | Purpose | IP Range | Gateway |
|----------------|---------|----------|---------|
| 192.168.1.0/24 | Control Plane & Load Balancer | 192.168.1.1-254 | 192.168.1.1 |
| 192.168.2.0/24 | Big Worker Nodes (High Performance) | 192.168.2.1-254 | 192.168.2.1 |
| 192.168.3.0/24 | Medium Worker Nodes (Standard) | 192.168.3.1-254 | 192.168.3.1 |
| 192.168.4.0/24 | Small Worker Nodes (Development) | 192.168.4.1-254 | 192.168.4.1 |
| 192.168.5.0/24 | Storage Network | 192.168.5.1-254 | 192.168.5.1 |

### Node IP Assignments

#### Control Plane Nodes (192.168.1.0/24)
- Master-1: 192.168.1.10
- Master-2: 192.168.1.11
- Master-3: 192.168.1.12
- Load Balancer: 192.168.1.100

#### Big Worker Nodes (192.168.2.0/24)
- Worker-Big-1: 192.168.2.10
- Worker-Big-2: 192.168.2.11
- Worker-Big-3: 192.168.2.12

**Reserved IPs:**
- Jenkins: 192.168.2.201
- ArgoCD: 192.168.2.202
- Grafana: 192.168.2.203
- Artifactory: 192.168.2.204

#### Medium Worker Nodes (192.168.3.0/24)
- Worker-Medium-1: 192.168.3.10
- Worker-Medium-2: 192.168.3.11
- Worker-Medium-3: 192.168.3.12

**Reserved IPs:**
- Ingress Controller: 192.168.3.201
- Lab Applications: 192.168.3.202
- Development Tools: 192.168.3.203

#### Small Worker Nodes (192.168.4.0/24)
- Worker-Small-1: 192.168.4.10
- Worker-Small-2: 192.168.4.11
- Worker-Small-3: 192.168.4.12

**Reserved IPs:**
- Development Apps: 192.168.4.201
- Testing Workloads: 192.168.4.202
- Experimental Features: 192.168.4.203

#### Storage Nodes (192.168.5.0/24)
- Storage-1: 192.168.5.10
- Storage-2: 192.168.5.11
- Storage-3: 192.168.5.12

**Reserved IPs:**
- NFS Server: 192.168.5.100
- Backup Server: 192.168.5.101
- Storage API: 192.168.5.102

## Configuration Files

### terraform.tfvars

Infrastructure configuration file containing:

- **Network Configuration**: IP addresses, gateways, DNS servers
- **Kubernetes Configuration**: Version, container runtime, CNI plugin
- **Security Configuration**: RBAC, network policies, pod security
- **Storage Configuration**: Local storage, NFS settings
- **Resource Configuration**: CPU, memory, storage limits

### secrets.yaml

Application secrets file containing:

- **Jenkins Secrets**: Admin password, API tokens
- **Grafana Secrets**: Admin password, secret keys
- **ArgoCD Secrets**: Admin password, server secrets
- **Artifactory Secrets**: Admin password, join keys
- **Database Secrets**: Passwords for databases
- **External Service Secrets**: GitHub tokens, Docker registry passwords
- **SSL/TLS Certificates**: Certificates and private keys

### kubernetes-config.yaml

Application configuration file containing:

- **Application Settings**: Environment, debug mode, log levels
- **Resource Limits**: CPU and memory limits for applications
- **Network Configuration**: Ingress settings, MetalLB configuration
- **Storage Configuration**: Default storage classes, backup settings
- **Security Configuration**: RBAC, network policies, pod security

## Environment-Specific Configurations

### Development Environment (dev)

**Characteristics:**
- Relaxed security (simple passwords)
- Minimal resource limits
- Open access
- Debug mode enabled

**Configuration:**
```yaml
app.environment: "dev"
app.debug: "true"
app.log_level: "debug"
security.pod_security_policies: "false"
ingress.ssl_redirect: "false"
```

### Staging Environment (staging)

**Characteristics:**
- Moderate security
- Medium resource limits
- Limited access
- Production-like configuration

**Configuration:**
```yaml
app.environment: "staging"
app.debug: "false"
app.log_level: "info"
security.pod_security_policies: "true"
ingress.ssl_redirect: "true"
```

### Production Environment (prod)

**Characteristics:**
- Strict security
- High resource limits
- Restricted access
- Full production configuration

**Configuration:**
```yaml
app.environment: "prod"
app.debug: "false"
app.log_level: "warn"
security.pod_security_policies: "true"
security.network_policies: "true"
ingress.ssl_redirect: "true"
```

## Usage Examples

### Generate Development Configuration

```bash
# Generate configuration for development
./configs/scripts/generate-config.sh dev

# This creates:
# - configs/environments/dev/terraform.tfvars
# - configs/environments/dev/secrets.yaml
# - configs/environments/dev/kubernetes-config.yaml
```

### Customize Network Configuration

```bash
# Edit network settings
nano configs/environments/dev/terraform.tfvars

# Change IP addresses if needed
control_plane_ips = ["192.168.1.10", "192.168.1.11", "192.168.1.12"]
big_worker_ips = ["192.168.2.10", "192.168.2.11", "192.168.2.12"]
```

### Deploy with Custom Configuration

```bash
# Deploy with YAML manifests
./src/scripts/deploy-all.sh

# Deploy with Helm charts
./src/scripts/deploy-helm.sh
```

## Security Considerations

### Secrets Management

1. **Never commit secrets to version control**
2. **Use environment-specific secrets**
3. **Rotate passwords regularly**
4. **Use external secrets management for production**

### Network Security

1. **Segment networks by workload type**
2. **Apply network policies**
3. **Use RBAC for access control**
4. **Enable pod security standards**

### Configuration Security

1. **Validate all configuration files**
2. **Use least privilege principle**
3. **Monitor configuration changes**
4. **Backup configuration regularly**

## Troubleshooting

### Common Issues

#### 1. IP Address Conflicts
```bash
# Check for IP conflicts
nmap -sn 192.168.1.0/24

# Verify network configuration
ip addr show
```

#### 2. Configuration Validation Errors
```bash
# Validate Terraform configuration
cd configs/environments/dev
terraform validate -var-file=terraform.tfvars

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('secrets.yaml'))"
```

#### 3. Network Connectivity Issues
```bash
# Test network connectivity
ping 192.168.1.10  # Control plane
ping 192.168.2.10  # Big worker
ping 192.168.3.10  # Medium worker
```

### Getting Help

1. **Check the documentation**: `configs/documentation/`
2. **Validate configuration**: Use the validation scripts
3. **Review logs**: Check application and system logs
4. **Test connectivity**: Verify network connectivity

## Русский

Эта директория содержит все файлы конфигурации и шаблоны для проекта Kubernetes Baremetal Lab.

## Структура директории

```
configs/
├── environments/           # Окружения-специфичные конфигурации
│   ├── dev/               # Окружение разработки
│   │   ├── terraform.tfvars
│   │   ├── secrets.yaml
│   │   └── kubernetes-config.yaml
│   ├── staging/           # Staging окружение
│   │   ├── terraform.tfvars
│   │   ├── secrets.yaml
│   │   └── kubernetes-config.yaml
│   └── prod/              # Продакшен окружение
│       ├── terraform.tfvars
│       ├── secrets.yaml
│       └── kubernetes-config.yaml
├── templates/             # Шаблоны конфигурации
│   ├── kubernetes-config.template.yaml
│   └── secrets.template.yaml
├── validation/            # Схемы валидации конфигурации
│   └── schema.yaml
├── scripts/               # Скрипты управления конфигурацией
│   └── generate-config.sh
└── documentation/         # Документация по конфигурации
    ├── architecture-overview.md
    ├── configuration-guide.md
    └── installation-instructions.md
```

## Быстрый старт

### 1. Генерация конфигурации для вашего окружения

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

- **terraform.tfvars**: Конфигурация инфраструктуры (IP адреса, сетевые настройки)
- **secrets.yaml**: Секреты и пароли приложений
- **kubernetes-config.yaml**: Настройки приложений и лимиты ресурсов

### 3. Валидация конфигурации

```bash
# Валидация сгенерированной конфигурации
./configs/scripts/generate-config.sh dev --validate

# Сухой запуск для просмотра того, что будет сгенерировано
./configs/scripts/generate-config.sh dev --dry-run
```

## Сетевая архитектура

### Диапазоны IP адресов

| Сетевой сегмент | Назначение | Диапазон IP | Шлюз |
|----------------|------------|-------------|------|
| 192.168.1.0/24 | Control Plane и Load Balancer | 192.168.1.1-254 | 192.168.1.1 |
| 192.168.2.0/24 | Большие Worker узлы (Высокая производительность) | 192.168.2.1-254 | 192.168.2.1 |
| 192.168.3.0/24 | Средние Worker узлы (Стандартные) | 192.168.3.1-254 | 192.168.3.1 |
| 192.168.4.0/24 | Малые Worker узлы (Разработка) | 192.168.4.1-254 | 192.168.4.1 |
| 192.168.5.0/24 | Сеть хранилища | 192.168.5.1-254 | 192.168.5.1 |

### Назначения IP узлов

#### Узлы Control Plane (192.168.1.0/24)
- Master-1: 192.168.1.10
- Master-2: 192.168.1.11
- Master-3: 192.168.1.12
- Load Balancer: 192.168.1.100

#### Большие Worker узлы (192.168.2.0/24)
- Worker-Big-1: 192.168.2.10
- Worker-Big-2: 192.168.2.11
- Worker-Big-3: 192.168.2.12

**Зарезервированные IP:**
- Jenkins: 192.168.2.201
- ArgoCD: 192.168.2.202
- Grafana: 192.168.2.203
- Artifactory: 192.168.2.204

#### Средние Worker узлы (192.168.3.0/24)
- Worker-Medium-1: 192.168.3.10
- Worker-Medium-2: 192.168.3.11
- Worker-Medium-3: 192.168.3.12

**Зарезервированные IP:**
- Ingress Controller: 192.168.3.201
- Лабораторные приложения: 192.168.3.202
- Инструменты разработки: 192.168.3.203

#### Малые Worker узлы (192.168.4.0/24)
- Worker-Small-1: 192.168.4.10
- Worker-Small-2: 192.168.4.11
- Worker-Small-3: 192.168.4.12

**Зарезервированные IP:**
- Приложения разработки: 192.168.4.201
- Тестовые нагрузки: 192.168.4.202
- Экспериментальные функции: 192.168.4.203

#### Узлы хранилища (192.168.5.0/24)
- Storage-1: 192.168.5.10
- Storage-2: 192.168.5.11
- Storage-3: 192.168.5.12

**Зарезервированные IP:**
- NFS сервер: 192.168.5.100
- Сервер резервного копирования: 192.168.5.101
- Storage API: 192.168.5.102

## Файлы конфигурации

### terraform.tfvars

Файл конфигурации инфраструктуры, содержащий:

- **Сетевая конфигурация**: IP адреса, шлюзы, DNS серверы
- **Конфигурация Kubernetes**: Версия, container runtime, CNI плагин
- **Конфигурация безопасности**: RBAC, сетевые политики, безопасность подов
- **Конфигурация хранилища**: Локальное хранилище, настройки NFS
- **Конфигурация ресурсов**: Лимиты CPU, памяти, хранилища

### secrets.yaml

Файл секретов приложений, содержащий:

- **Секреты Jenkins**: Пароль администратора, API токены
- **Секреты Grafana**: Пароль администратора, секретные ключи
- **Секреты ArgoCD**: Пароль администратора, секреты сервера
- **Секреты Artifactory**: Пароль администратора, ключи подключения
- **Секреты баз данных**: Пароли для баз данных
- **Секреты внешних сервисов**: GitHub токены, пароли Docker registry
- **SSL/TLS сертификаты**: Сертификаты и приватные ключи

### kubernetes-config.yaml

Файл конфигурации приложений, содержащий:

- **Настройки приложений**: Окружение, режим отладки, уровни логирования
- **Лимиты ресурсов**: Лимиты CPU и памяти для приложений
- **Сетевая конфигурация**: Настройки Ingress, конфигурация MetalLB
- **Конфигурация хранилища**: Классы хранилищ по умолчанию, настройки резервного копирования
- **Конфигурация безопасности**: RBAC, сетевые политики, безопасность подов

## Окружения-специфичные конфигурации

### Окружение разработки (dev)

**Характеристики:**
- Расслабленная безопасность (простые пароли)
- Минимальные лимиты ресурсов
- Открытый доступ
- Включен режим отладки

**Конфигурация:**
```yaml
app.environment: "dev"
app.debug: "true"
app.log_level: "debug"
security.pod_security_policies: "false"
ingress.ssl_redirect: "false"
```

### Staging окружение (staging)

**Характеристики:**
- Умеренная безопасность
- Средние лимиты ресурсов
- Ограниченный доступ
- Конфигурация, похожая на продакшен

**Конфигурация:**
```yaml
app.environment: "staging"
app.debug: "false"
app.log_level: "info"
security.pod_security_policies: "true"
ingress.ssl_redirect: "true"
```

### Продакшен окружение (prod)

**Характеристики:**
- Строгая безопасность
- Высокие лимиты ресурсов
- Ограниченный доступ
- Полная продакшен конфигурация

**Конфигурация:**
```yaml
app.environment: "prod"
app.debug: "false"
app.log_level: "warn"
security.pod_security_policies: "true"
security.network_policies: "true"
ingress.ssl_redirect: "true"
```

## Примеры использования

### Генерация конфигурации разработки

```bash
# Генерация конфигурации для разработки
./configs/scripts/generate-config.sh dev

# Это создает:
# - configs/environments/dev/terraform.tfvars
# - configs/environments/dev/secrets.yaml
# - configs/environments/dev/kubernetes-config.yaml
```

### Настройка сетевой конфигурации

```bash
# Редактирование сетевых настроек
nano configs/environments/dev/terraform.tfvars

# Изменение IP адресов при необходимости
control_plane_ips = ["192.168.1.10", "192.168.1.11", "192.168.1.12"]
big_worker_ips = ["192.168.2.10", "192.168.2.11", "192.168.2.12"]
```

### Развертывание с пользовательской конфигурацией

```bash
# Развертывание с YAML манифестами
./src/scripts/deploy-all.sh

# Развертывание с Helm чартами
./src/scripts/deploy-helm.sh
```

## Соображения безопасности

### Управление секретами

1. **Никогда не коммитьте секреты в контроль версий**
2. **Используйте окружения-специфичные секреты**
3. **Регулярно меняйте пароли**
4. **Используйте внешнее управление секретами для продакшена**

### Сетевая безопасность

1. **Сегментируйте сети по типам нагрузок**
2. **Применяйте сетевые политики**
3. **Используйте RBAC для контроля доступа**
4. **Включайте стандарты безопасности подов**

### Безопасность конфигурации

1. **Валидируйте все файлы конфигурации**
2. **Используйте принцип наименьших привилегий**
3. **Мониторьте изменения конфигурации**
4. **Регулярно делайте резервные копии конфигурации**

## Устранение неполадок

### Общие проблемы

#### 1. Конфликты IP адресов
```bash
# Проверка конфликтов IP
nmap -sn 192.168.1.0/24

# Проверка сетевой конфигурации
ip addr show
```

#### 2. Ошибки валидации конфигурации
```bash
# Валидация конфигурации Terraform
cd configs/environments/dev
terraform validate -var-file=terraform.tfvars

# Валидация синтаксиса YAML
python3 -c "import yaml; yaml.safe_load(open('secrets.yaml'))"
```

#### 3. Проблемы сетевого подключения
```bash
# Тестирование сетевого подключения
ping 192.168.1.10  # Control plane
ping 192.168.2.10  # Большой worker
ping 192.168.3.10  # Средний worker
```

### Получение помощи

1. **Проверьте документацию**: `configs/documentation/`
2. **Валидируйте конфигурацию**: Используйте скрипты валидации
3. **Просмотрите логи**: Проверьте логи приложений и системы
4. **Протестируйте подключение**: Проверьте сетевое подключение 