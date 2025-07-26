# Architecture Overview / Обзор архитектуры

[English](#english) | [Русский](#russian)

## English

### System Architecture

The Kubernetes Baremetal Lab follows a modular architecture designed for scalability, maintainability, and production readiness.

#### Core Components

1. **Infrastructure Layer**
   - Bare metal servers (control plane and worker nodes)
   - Network infrastructure (load balancers, switches)
   - Storage systems (local storage, network storage)

2. **Provisioning Layer**
   - Terraform for infrastructure provisioning
   - Ansible for configuration management
   - Custom scripts for automation

3. **Kubernetes Layer**
   - Control plane components (API server, etcd, scheduler, controller manager)
   - Worker node components (kubelet, container runtime)
   - Network plugins (CNI)
   - Storage plugins (CSI)

4. **Application Layer**
   - Monitoring stack (Prometheus, Grafana)
   - Logging stack (ELK/Fluentd)
   - Security components (RBAC, network policies)

#### Network Architecture

```
Internet
    │
    ▼
Load Balancer (HAProxy/nginx)
    │
    ▼
Control Plane Nodes (3+ nodes)
    │
    ▼
Worker Nodes (N nodes)
    │
    ▼
Storage Network
```

#### Security Architecture

- **Network Security**: Firewall rules, network policies
- **Authentication**: RBAC, service accounts
- **Authorization**: Role-based access control
- **Encryption**: TLS for all communications, secrets encryption

## Русский

### Системная архитектура

Kubernetes Baremetal Lab следует модульной архитектуре, разработанной для масштабируемости, поддерживаемости и готовности к продакшену.

#### Основные компоненты

1. **Слой инфраструктуры**
   - Bare metal серверы (control plane и worker узлы)
   - Сетевая инфраструктура (балансировщики нагрузки, коммутаторы)
   - Системы хранения (локальное хранилище, сетевое хранилище)

2. **Слой подготовки**
   - Terraform для подготовки инфраструктуры
   - Ansible для управления конфигурациями
   - Пользовательские скрипты для автоматизации

3. **Слой Kubernetes**
   - Компоненты control plane (API server, etcd, scheduler, controller manager)
   - Компоненты worker узлов (kubelet, container runtime)
   - Сетевые плагины (CNI)
   - Плагины хранилища (CSI)

4. **Слой приложений**
   - Стек мониторинга (Prometheus, Grafana)
   - Стек логирования (ELK/Fluentd)
   - Компоненты безопасности (RBAC, network policies)

#### Сетевая архитектура

```
Интернет
    │
    ▼
Балансировщик нагрузки (HAProxy/nginx)
    │
    ▼
Control Plane узлы (3+ узла)
    │
    ▼
Worker узлы (N узлов)
    │
    ▼
Сеть хранения
```

#### Архитектура безопасности

- **Сетевая безопасность**: Правила файрвола, сетевые политики
- **Аутентификация**: RBAC, service accounts
- **Авторизация**: Ролевой контроль доступа
- **Шифрование**: TLS для всех коммуникаций, шифрование секретов

### Требования к системе

#### Минимальные требования

- **Control Plane**: 2 CPU, 4GB RAM, 50GB storage
- **Worker Nodes**: 2 CPU, 4GB RAM, 100GB storage
- **Network**: 1Gbps connectivity

#### Рекомендуемые требования

- **Control Plane**: 4 CPU, 8GB RAM, 100GB storage
- **Worker Nodes**: 8 CPU, 16GB RAM, 500GB storage
- **Network**: 10Gbps connectivity

### Компоненты развертывания

1. **Terraform Modules**
   - Network configuration
   - Server provisioning
   - Load balancer setup

2. **Ansible Playbooks**
   - System preparation
   - Kubernetes installation
   - Post-installation configuration

3. **Kubernetes Manifests**
   - Core components
   - Add-ons and extensions
   - Application deployments 