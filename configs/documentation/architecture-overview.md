# Kubernetes Baremetal Lab - Architecture Overview
# Обзор архитектуры Kubernetes Baremetal Lab

[English](#english) | [Русский](#russian)

## English

This document provides a comprehensive overview of the Kubernetes Baremetal Lab architecture, including namespace design, IP address ranges, and component relationships.

## Network Architecture

### IP Address Ranges

#### Infrastructure Network (192.168.1.0/24) - Control Plane & Load Balancer
```
Network: 192.168.1.0/24
Gateway: 192.168.1.1
Subnet Mask: 255.255.255.0

Control Plane Nodes:
- Master-1: 192.168.1.10
- Master-2: 192.168.1.11
- Master-3: 192.168.1.12

Load Balancer: 192.168.1.100
```

#### Big Worker Nodes Network (192.168.2.0/24) - High Performance
```
Network: 192.168.2.0/24
Gateway: 192.168.2.1
Subnet Mask: 255.255.255.0

Big Worker Nodes:
- Worker-Big-1: 192.168.2.10
- Worker-Big-2: 192.168.2.11
- Worker-Big-3: 192.168.2.12

Reserved IPs:
- Jenkins: 192.168.2.201
- ArgoCD: 192.168.2.202
- Grafana: 192.168.2.203
- Artifactory: 192.168.2.204
```

#### Medium Worker Nodes Network (192.168.3.0/24) - Standard Performance
```
Network: 192.168.3.0/24
Gateway: 192.168.3.1
Subnet Mask: 255.255.255.0

Medium Worker Nodes:
- Worker-Medium-1: 192.168.3.10
- Worker-Medium-2: 192.168.3.11
- Worker-Medium-3: 192.168.3.12

Reserved IPs:
- Ingress Controller: 192.168.3.201
- Lab Applications: 192.168.3.202
- Development Tools: 192.168.3.203
```

#### Small Worker Nodes Network (192.168.4.0/24) - Development/Testing
```
Network: 192.168.4.0/24
Gateway: 192.168.4.1
Subnet Mask: 255.255.255.0

Small Worker Nodes:
- Worker-Small-1: 192.168.4.10
- Worker-Small-2: 192.168.4.11
- Worker-Small-3: 192.168.4.12

Reserved IPs:
- Development Apps: 192.168.4.201
- Testing Workloads: 192.168.4.202
- Experimental Features: 192.168.4.203
```

#### Storage Network (192.168.5.0/24) - Storage & Backup
```
Network: 192.168.5.0/24
Gateway: 192.168.5.1
Subnet Mask: 255.255.255.0

Storage Nodes:
- Storage-1: 192.168.5.10
- Storage-2: 192.168.5.11
- Storage-3: 192.168.5.12

NFS Server: 192.168.5.100
Backup Server: 192.168.5.101
```

#### Kubernetes Service Network (10.96.0.0/12)
```
Service CIDR: 10.96.0.0/12
Range: 10.96.0.0 - 10.255.255.255

Core Services:
- kube-dns: 10.96.0.10
- kubernetes: 10.96.0.1

Application Services:
- Jenkins: 10.96.1.10
- ArgoCD: 10.96.1.20
- Grafana: 10.96.1.30
- Prometheus: 10.96.1.40
- Artifactory: 10.96.1.50
```

#### Kubernetes Pod Network (10.244.0.0/16)
```
Pod CIDR: 10.244.0.0/16
Range: 10.244.0.0 - 10.244.255.255

Node Pod Ranges:
- Master-1: 10.244.0.0/24
- Master-2: 10.244.1.0/24
- Master-3: 10.244.2.0/24
- Worker-Big-1: 10.244.10.0/24
- Worker-Big-2: 10.244.11.0/24
- Worker-Big-3: 10.244.12.0/24
- Worker-Medium-1: 10.244.20.0/24
- Worker-Medium-2: 10.244.21.0/24
- Worker-Medium-3: 10.244.22.0/24
- Worker-Small-1: 10.244.30.0/24
- Worker-Small-2: 10.244.31.0/24
- Worker-Small-3: 10.244.32.0/24
```

#### MetalLB Load Balancer Pools
```
Big Nodes Pool (192.168.2.200-250):
- Jenkins: 192.168.2.201
- ArgoCD: 192.168.2.202
- Grafana: 192.168.2.203
- Artifactory: 192.168.2.204

Medium Nodes Pool (192.168.3.200-250):
- Ingress Controller: 192.168.3.201
- Lab Applications: 192.168.3.202
- Development Tools: 192.168.3.203

Small Nodes Pool (192.168.4.200-250):
- Development Apps: 192.168.4.201
- Testing Workloads: 192.168.4.202
- Experimental Features: 192.168.4.203
```

## Network Topology

### Physical Network Layout
```
Internet
    ↓
Router (192.168.1.1)
    ↓
    ├── 192.168.1.0/24 (Control Plane + Load Balancer)
    ├── 192.168.2.0/24 (Big Worker Nodes)
    ├── 192.168.3.0/24 (Medium Worker Nodes)
    ├── 192.168.4.0/24 (Small Worker Nodes)
    └── 192.168.5.0/24 (Storage Network)
```

### Network Segmentation Benefits
1. **Security**: Isolated networks for different workload types
2. **Performance**: Dedicated bandwidth for high-performance workloads
3. **Management**: Easier network policy management
4. **Scalability**: Independent scaling of different node types
5. **Monitoring**: Separate monitoring and alerting per network segment

## Namespace Architecture

### Core System Namespaces

#### 1. **kube-system** (Built-in)
- **Purpose**: Kubernetes system components
- **Components**: kube-apiserver, kube-controller-manager, kube-scheduler, kube-proxy
- **Resource Limits**: System managed
- **Network Policies**: Default Kubernetes policies

#### 2. **kube-public** (Built-in)
- **Purpose**: Publicly accessible resources
- **Components**: Cluster information
- **Resource Limits**: Minimal
- **Network Policies**: Open access

#### 3. **kube-node-lease** (Built-in)
- **Purpose**: Node lease objects
- **Components**: Node heartbeat information
- **Resource Limits**: Minimal
- **Network Policies**: Internal only

### Application Namespaces

#### 4. **jenkins** (CI/CD)
- **Purpose**: Continuous Integration and Continuous Deployment
- **Components**: Jenkins server, agents, pipelines
- **Resource Limits**: 
  - CPU: 2 cores
  - Memory: 4GB
  - Storage: 50GB
- **Node Selector**: `node-type=big`
- **Tolerations**: `dedicated=jenkins:NoSchedule`
- **Network**: 192.168.2.0/24
- **Network Policies**: Restricted to CI/CD traffic
- **Services**:
  - Jenkins HTTP: 8080
  - Jenkins JNLP: 50000

#### 5. **gitops** (GitOps Management)
- **Purpose**: GitOps workflow management
- **Components**: ArgoCD server, application controller, repo server
- **Resource Limits**:
  - CPU: 1 core
  - Memory: 2GB
  - Storage: 10GB
- **Node Selector**: `node-type=big`
- **Network**: 192.168.2.0/24
- **Network Policies**: Git repository access
- **Services**:
  - ArgoCD Server: 80, 443
  - ArgoCD Repo Server: 8081

#### 6. **monitoring** (Observability)
- **Purpose**: Monitoring and alerting
- **Components**: Prometheus, Grafana, AlertManager
- **Resource Limits**:
  - CPU: 1 core
  - Memory: 2GB
  - Storage: 20GB
- **Node Selector**: `node-type=big`
- **Network**: 192.168.2.0/24
- **Network Policies**: Monitoring data collection
- **Services**:
  - Grafana: 3000
  - Prometheus: 9090
  - AlertManager: 9093

#### 7. **artifacts** (Artifact Management)
- **Purpose**: Binary artifact storage and management
- **Components**: JFrog Artifactory
- **Resource Limits**:
  - CPU: 2 cores
  - Memory: 4GB
  - Storage: 100GB
- **Node Selector**: `node-type=big`
- **Network**: 192.168.2.0/24
- **Network Policies**: Artifact upload/download
- **Services**:
  - Artifactory: 8081, 8082

#### 8. **lab-stands** (Laboratory Applications)
- **Purpose**: Development and testing applications
- **Components**: Example applications, test workloads
- **Resource Limits**:
  - CPU: 0.5 cores
  - Memory: 1GB
  - Storage: 5GB
- **Node Selector**: `node-type=medium`
- **Network**: 192.168.3.0/24
- **Network Policies**: Development access
- **Services**: Various application ports

### Infrastructure Namespaces

#### 9. **ingress-nginx** (Ingress Controller)
- **Purpose**: HTTP/HTTPS traffic routing
- **Components**: NGINX Ingress Controller
- **Resource Limits**:
  - CPU: 1 core
  - Memory: 1GB
- **Node Selector**: `node-type=medium`
- **Network**: 192.168.3.0/24
- **Network Policies**: Ingress traffic
- **Services**:
  - HTTP: 80
  - HTTPS: 443

#### 10. **metallb-system** (Load Balancer)
- **Purpose**: Bare metal load balancer
- **Components**: MetalLB controller, speakers
- **Resource Limits**:
  - CPU: 0.5 cores
  - Memory: 512MB
- **Node Selector**: All nodes
- **Network**: All networks
- **Network Policies**: Load balancer traffic
- **Services**: Layer 2 advertisement

#### 11. **storage** (Storage Management)
- **Purpose**: Storage class and volume management
- **Components**: Storage classes, persistent volumes
- **Resource Limits**: Storage only
- **Node Selector**: Storage nodes
- **Network**: 192.168.5.0/24
- **Network Policies**: Storage access
- **Services**: Storage API

## Node Architecture

### Control Plane Nodes (3x) - 192.168.1.0/24
```
Node Type: Master/Control Plane
Hardware: 4 CPU, 8GB RAM, 100GB Storage
Network: 192.168.1.0/24
Labels:
  - node-role.kubernetes.io/control-plane=true
  - node-type=control-plane
Taints:
  - node-role.kubernetes.io/control-plane:NoSchedule
Components:
  - kube-apiserver
  - kube-controller-manager
  - kube-scheduler
  - etcd
```

### Worker Nodes (9x)

#### Big Nodes (3x) - 192.168.2.0/24 - High Performance
```
Node Type: Big Worker
Hardware: 8 CPU, 16GB RAM, 500GB Storage
Network: 192.168.2.0/24
Labels:
  - node-type=big
  - storage-type=ssd
Taints:
  - dedicated=jenkins:NoSchedule (Node 1)
  - dedicated=monitoring:NoSchedule (Node 2)
  - dedicated=artifacts:NoSchedule (Node 3)
Workloads:
  - Jenkins (192.168.2.201)
  - ArgoCD (192.168.2.202)
  - Grafana (192.168.2.203)
  - Artifactory (192.168.2.204)
```

#### Medium Nodes (3x) - 192.168.3.0/24 - Standard Performance
```
Node Type: Medium Worker
Hardware: 4 CPU, 8GB RAM, 250GB Storage
Network: 192.168.3.0/24
Labels:
  - node-type=medium
  - storage-type=hdd
Workloads:
  - Ingress Controller (192.168.3.201)
  - Lab Applications (192.168.3.202)
  - Development Tools (192.168.3.203)
```

#### Small Nodes (3x) - 192.168.4.0/24 - Development/Testing
```
Node Type: Small Worker
Hardware: 2 CPU, 4GB RAM, 100GB Storage
Network: 192.168.4.0/24
Labels:
  - node-type=small
  - storage-type=hdd
Workloads:
  - Development Applications (192.168.4.201)
  - Testing Workloads (192.168.4.202)
  - Experimental Features (192.168.4.203)
```

### Storage Nodes (3x) - 192.168.5.0/24
```
Node Type: Storage
Hardware: 4 CPU, 8GB RAM, 2TB Storage
Network: 192.168.5.0/24
Labels:
  - node-type=storage
  - storage-type=ssd
Services:
  - NFS Server (192.168.5.100)
  - Backup Server (192.168.5.101)
  - Storage API (192.168.5.102)
```

## Component Relationships

### Data Flow
```
Internet → Router → Load Balancer → Ingress Controller → Applications
                                    ↓
                              Monitoring Stack
                                    ↓
                              Logging System
```

### Service Dependencies
```
Jenkins → Git Repositories → ArgoCD → Kubernetes API
    ↓
Artifactory ← Build Artifacts
    ↓
Monitoring Stack ← Metrics Collection
```

### Network Traffic Patterns
```
External → Ingress (80/443) → Services (ClusterIP) → Pods
Load Balancer → Services (LoadBalancer) → Pods
Pods → CoreDNS → External Services
```

## Security Architecture

### Network Policies by Segment
- **192.168.1.0/24**: Control plane traffic only
- **192.168.2.0/24**: High-performance application traffic
- **192.168.3.0/24**: Standard application traffic
- **192.168.4.0/24**: Development and testing traffic
- **192.168.5.0/24**: Storage traffic only

### RBAC Configuration
- **Cluster Admin**: Full cluster access
- **Namespace Admin**: Namespace-level access
- **Developer**: Application deployment access
- **Viewer**: Read-only access

### Pod Security Standards
- **Privileged**: System components only
- **Baseline**: Most application workloads
- **Restricted**: Security-sensitive applications

## Storage Architecture

### Storage Classes by Network
- **local-storage**: Local node storage (default)
- **ssd-storage**: SSD-based storage (192.168.2.0/24)
- **hdd-storage**: HDD-based storage (192.168.3.0/24, 192.168.4.0/24)
- **nfs-storage**: Network file system (192.168.5.0/24)

### Persistent Volumes
- **Jenkins**: 50GB local storage (192.168.2.0/24)
- **Grafana**: 10GB local storage (192.168.2.0/24)
- **Artifactory**: 100GB local storage (192.168.2.0/24)
- **Monitoring**: 20GB local storage (192.168.2.0/24)

## Monitoring Architecture

### Metrics Collection
- **Node Exporter**: Node-level metrics
- **kube-state-metrics**: Kubernetes object metrics
- **Prometheus**: Metrics storage and querying
- **Grafana**: Metrics visualization

### Logging
- **Fluentd**: Log collection
- **Elasticsearch**: Log storage
- **Kibana**: Log visualization

### Alerting
- **AlertManager**: Alert routing and grouping
- **Prometheus**: Alert rules evaluation
- **Grafana**: Alert visualization

## Русский

Этот документ предоставляет комплексный обзор архитектуры Kubernetes Baremetal Lab, включая дизайн namespace, диапазоны IP адресов и связи между компонентами.

## Сетевая архитектура

### Диапазоны IP адресов

#### Инфраструктурная сеть (192.168.1.0/24) - Control Plane и Load Balancer
```
Сеть: 192.168.1.0/24
Шлюз: 192.168.1.1
Маска подсети: 255.255.255.0

Узлы Control Plane:
- Master-1: 192.168.1.10
- Master-2: 192.168.1.11
- Master-3: 192.168.1.12

Load Balancer: 192.168.1.100
```

#### Сеть больших Worker узлов (192.168.2.0/24) - Высокая производительность
```
Сеть: 192.168.2.0/24
Шлюз: 192.168.2.1
Маска подсети: 255.255.255.0

Большие Worker узлы:
- Worker-Big-1: 192.168.2.10
- Worker-Big-2: 192.168.2.11
- Worker-Big-3: 192.168.2.12

Зарезервированные IP:
- Jenkins: 192.168.2.201
- ArgoCD: 192.168.2.202
- Grafana: 192.168.2.203
- Artifactory: 192.168.2.204
```

#### Сеть средних Worker узлов (192.168.3.0/24) - Стандартная производительность
```
Сеть: 192.168.3.0/24
Шлюз: 192.168.3.1
Маска подсети: 255.255.255.0

Средние Worker узлы:
- Worker-Medium-1: 192.168.3.10
- Worker-Medium-2: 192.168.3.11
- Worker-Medium-3: 192.168.3.12

Зарезервированные IP:
- Ingress Controller: 192.168.3.201
- Лабораторные приложения: 192.168.3.202
- Инструменты разработки: 192.168.3.203
```

#### Сеть малых Worker узлов (192.168.4.0/24) - Разработка/Тестирование
```
Сеть: 192.168.4.0/24
Шлюз: 192.168.4.1
Маска подсети: 255.255.255.0

Малые Worker узлы:
- Worker-Small-1: 192.168.4.10
- Worker-Small-2: 192.168.4.11
- Worker-Small-3: 192.168.4.12

Зарезервированные IP:
- Приложения разработки: 192.168.4.201
- Тестовые нагрузки: 192.168.4.202
- Экспериментальные функции: 192.168.4.203
```

#### Сеть хранилища (192.168.5.0/24) - Хранилище и резервное копирование
```
Сеть: 192.168.5.0/24
Шлюз: 192.168.5.1
Маска подсети: 255.255.255.0

Узлы хранилища:
- Storage-1: 192.168.5.10
- Storage-2: 192.168.5.11
- Storage-3: 192.168.5.12

NFS сервер: 192.168.5.100
Сервер резервного копирования: 192.168.5.101
```

#### Сеть сервисов Kubernetes (10.96.0.0/12)
```
CIDR сервисов: 10.96.0.0/12
Диапазон: 10.96.0.0 - 10.255.255.255

Основные сервисы:
- kube-dns: 10.96.0.10
- kubernetes: 10.96.0.1

Сервисы приложений:
- Jenkins: 10.96.1.10
- ArgoCD: 10.96.1.20
- Grafana: 10.96.1.30
- Prometheus: 10.96.1.40
- Artifactory: 10.96.1.50
```

#### Сеть подов Kubernetes (10.244.0.0/16)
```
CIDR подов: 10.244.0.0/16
Диапазон: 10.244.0.0 - 10.244.255.255

Диапазоны подов узлов:
- Master-1: 10.244.0.0/24
- Master-2: 10.244.1.0/24
- Master-3: 10.244.2.0/24
- Worker-Big-1: 10.244.10.0/24
- Worker-Big-2: 10.244.11.0/24
- Worker-Big-3: 10.244.12.0/24
- Worker-Medium-1: 10.244.20.0/24
- Worker-Medium-2: 10.244.21.0/24
- Worker-Medium-3: 10.244.22.0/24
- Worker-Small-1: 10.244.30.0/24
- Worker-Small-2: 10.244.31.0/24
- Worker-Small-3: 10.244.32.0/24
```

#### Пулы Load Balancer MetalLB
```
Пул больших узлов (192.168.2.200-250):
- Jenkins: 192.168.2.201
- ArgoCD: 192.168.2.202
- Grafana: 192.168.2.203
- Artifactory: 192.168.2.204

Пул средних узлов (192.168.3.200-250):
- Ingress Controller: 192.168.3.201
- Лабораторные приложения: 192.168.3.202
- Инструменты разработки: 192.168.3.203

Пул малых узлов (192.168.4.200-250):
- Приложения разработки: 192.168.4.201
- Тестовые нагрузки: 192.168.4.202
- Экспериментальные функции: 192.168.4.203
```

## Топология сети

### Физическая схема сети
```
Интернет
    ↓
Роутер (192.168.1.1)
    ↓
    ├── 192.168.1.0/24 (Control Plane + Load Balancer)
    ├── 192.168.2.0/24 (Большие Worker узлы)
    ├── 192.168.3.0/24 (Средние Worker узлы)
    ├── 192.168.4.0/24 (Малые Worker узлы)
    └── 192.168.5.0/24 (Сеть хранилища)
```

### Преимущества сегментации сети
1. **Безопасность**: Изолированные сети для разных типов нагрузок
2. **Производительность**: Выделенная пропускная способность для высокопроизводительных нагрузок
3. **Управление**: Упрощенное управление сетевыми политиками
4. **Масштабируемость**: Независимое масштабирование разных типов узлов
5. **Мониторинг**: Отдельный мониторинг и алертинг для каждого сетевого сегмента

## Архитектура Namespace

### Основные системные namespace

#### 1. **kube-system** (Встроенный)
- **Назначение**: Системные компоненты Kubernetes
- **Компоненты**: kube-apiserver, kube-controller-manager, kube-scheduler, kube-proxy
- **Лимиты ресурсов**: Управляется системой
- **Сетевые политики**: Стандартные политики Kubernetes

#### 2. **kube-public** (Встроенный)
- **Назначение**: Публично доступные ресурсы
- **Компоненты**: Информация о кластере
- **Лимиты ресурсов**: Минимальные
- **Сетевые политики**: Открытый доступ

#### 3. **kube-node-lease** (Встроенный)
- **Назначение**: Объекты аренды узлов
- **Компоненты**: Информация о сердцебиении узлов
- **Лимиты ресурсов**: Минимальные
- **Сетевые политики**: Только внутренний доступ

### Namespace приложений

#### 4. **jenkins** (CI/CD)
- **Назначение**: Непрерывная интеграция и развертывание
- **Компоненты**: Jenkins сервер, агенты, пайплайны
- **Лимиты ресурсов**: 
  - CPU: 2 ядра
  - Память: 4GB
  - Хранилище: 50GB
- **Node Selector**: `node-type=big`
- **Tolerations**: `dedicated=jenkins:NoSchedule`
- **Сеть**: 192.168.2.0/24
- **Сетевые политики**: Ограниченный CI/CD трафик
- **Сервисы**:
  - Jenkins HTTP: 8080
  - Jenkins JNLP: 50000

#### 5. **gitops** (GitOps управление)
- **Назначение**: Управление GitOps workflow
- **Компоненты**: ArgoCD сервер, контроллер приложений, repo сервер
- **Лимиты ресурсов**:
  - CPU: 1 ядро
  - Память: 2GB
  - Хранилище: 10GB
- **Node Selector**: `node-type=big`
- **Сеть**: 192.168.2.0/24
- **Сетевые политики**: Доступ к Git репозиториям
- **Сервисы**:
  - ArgoCD Server: 80, 443
  - ArgoCD Repo Server: 8081

#### 6. **monitoring** (Наблюдаемость)
- **Назначение**: Мониторинг и алертинг
- **Компоненты**: Prometheus, Grafana, AlertManager
- **Лимиты ресурсов**:
  - CPU: 1 ядро
  - Память: 2GB
  - Хранилище: 20GB
- **Node Selector**: `node-type=big`
- **Сеть**: 192.168.2.0/24
- **Сетевые политики**: Сбор данных мониторинга
- **Сервисы**:
  - Grafana: 3000
  - Prometheus: 9090
  - AlertManager: 9093

#### 7. **artifacts** (Управление артефактами)
- **Назначение**: Хранение и управление бинарными артефактами
- **Компоненты**: JFrog Artifactory
- **Лимиты ресурсов**:
  - CPU: 2 ядра
  - Память: 4GB
  - Хранилище: 100GB
- **Node Selector**: `node-type=big`
- **Сеть**: 192.168.2.0/24
- **Сетевые политики**: Загрузка/выгрузка артефактов
- **Сервисы**:
  - Artifactory: 8081, 8082

#### 8. **lab-stands** (Лабораторные приложения)
- **Назначение**: Приложения разработки и тестирования
- **Компоненты**: Примеры приложений, тестовые нагрузки
- **Лимиты ресурсов**:
  - CPU: 0.5 ядра
  - Память: 1GB
  - Хранилище: 5GB
- **Node Selector**: `node-type=medium`
- **Сеть**: 192.168.3.0/24
- **Сетевые политики**: Доступ разработки
- **Сервисы**: Различные порты приложений

### Инфраструктурные namespace

#### 9. **ingress-nginx** (Ingress контроллер)
- **Назначение**: Маршрутизация HTTP/HTTPS трафика
- **Компоненты**: NGINX Ingress Controller
- **Лимиты ресурсов**:
  - CPU: 1 ядро
  - Память: 1GB
- **Node Selector**: `node-type=medium`
- **Сеть**: 192.168.3.0/24
- **Сетевые политики**: Ingress трафик
- **Сервисы**:
  - HTTP: 80
  - HTTPS: 443

#### 10. **metallb-system** (Load Balancer)
- **Назначение**: Bare metal load balancer
- **Компоненты**: MetalLB контроллер, спикеры
- **Лимиты ресурсов**:
  - CPU: 0.5 ядра
  - Память: 512MB
- **Node Selector**: Все узлы
- **Сеть**: Все сети
- **Сетевые политики**: Трафик load balancer
- **Сервисы**: Layer 2 advertisement

#### 11. **storage** (Управление хранилищем)
- **Назначение**: Управление классами хранилищ и томами
- **Компоненты**: Классы хранилищ, persistent volumes
- **Лимиты ресурсов**: Только хранилище
- **Node Selector**: Storage nodes
- **Сеть**: 192.168.5.0/24
- **Сетевые политики**: Доступ к хранилищу
- **Сервисы**: Storage API

## Архитектура узлов

### Узлы Control Plane (3x) - 192.168.1.0/24
```
Тип узла: Master/Control Plane
Аппаратное обеспечение: 4 CPU, 8GB RAM, 100GB Storage
Сеть: 192.168.1.0/24
Метки:
  - node-role.kubernetes.io/control-plane=true
  - node-type=control-plane
Taints:
  - node-role.kubernetes.io/control-plane:NoSchedule
Компоненты:
  - kube-apiserver
  - kube-controller-manager
  - kube-scheduler
  - etcd
```

### Worker узлы (9x)

#### Большие узлы (3x) - 192.168.2.0/24 - Высокая производительность
```
Тип узла: Big Worker
Аппаратное обеспечение: 8 CPU, 16GB RAM, 500GB Storage
Сеть: 192.168.2.0/24
Метки:
  - node-type=big
  - storage-type=ssd
Taints:
  - dedicated=jenkins:NoSchedule (Узел 1)
  - dedicated=monitoring:NoSchedule (Узел 2)
  - dedicated=artifacts:NoSchedule (Узел 3)
Нагрузки:
  - Jenkins (192.168.2.201)
  - ArgoCD (192.168.2.202)
  - Grafana (192.168.2.203)
  - Artifactory (192.168.2.204)
```

#### Средние узлы (3x) - 192.168.3.0/24 - Стандартная производительность
```
Тип узла: Medium Worker
Аппаратное обеспечение: 4 CPU, 8GB RAM, 250GB Storage
Сеть: 192.168.3.0/24
Метки:
  - node-type=medium
  - storage-type=hdd
Нагрузки:
  - Ingress Controller (192.168.3.201)
  - Лабораторные приложения (192.168.3.202)
  - Инструменты разработки (192.168.3.203)
```

#### Малые узлы (3x) - 192.168.4.0/24 - Разработка/Тестирование
```
Тип узла: Small Worker
Аппаратное обеспечение: 2 CPU, 4GB RAM, 100GB Storage
Сеть: 192.168.4.0/24
Метки:
  - node-type=small
  - storage-type=hdd
Нагрузки:
  - Приложения разработки (192.168.4.201)
  - Тестовые нагрузки (192.168.4.202)
  - Экспериментальные функции (192.168.4.203)
```

### Узлы хранилища (3x) - 192.168.5.0/24
```
Тип узла: Storage
Аппаратное обеспечение: 4 CPU, 8GB RAM, 2TB Storage
Сеть: 192.168.5.0/24
Метки:
  - node-type=storage
  - storage-type=ssd
Сервисы:
  - NFS сервер (192.168.5.100)
  - Сервер резервного копирования (192.168.5.101)
  - Storage API (192.168.5.102)
```

## Связи компонентов

### Поток данных
```
Интернет → Роутер → Load Balancer → Ingress Controller → Приложения
                                    ↓
                              Стек мониторинга
                                    ↓
                              Система логирования
```

### Зависимости сервисов
```
Jenkins → Git репозитории → ArgoCD → Kubernetes API
    ↓
Artifactory ← Артефакты сборки
    ↓
Стек мониторинга ← Сбор метрик
```

### Паттерны сетевого трафика
```
Внешний → Ingress (80/443) → Сервисы (ClusterIP) → Поды
Load Balancer → Сервисы (LoadBalancer) → Поды
Поды → CoreDNS → Внешние сервисы
```

## Архитектура безопасности

### Сетевые политики по сегментам
- **192.168.1.0/24**: Только трафик control plane
- **192.168.2.0/24**: Трафик высокопроизводительных приложений
- **192.168.3.0/24**: Трафик стандартных приложений
- **192.168.4.0/24**: Трафик разработки и тестирования
- **192.168.5.0/24**: Только трафик хранилища

### Конфигурация RBAC
- **Cluster Admin**: Полный доступ к кластеру
- **Namespace Admin**: Доступ на уровне namespace
- **Developer**: Доступ к развертыванию приложений
- **Viewer**: Доступ только для чтения

### Стандарты безопасности подов
- **Privileged**: Только системные компоненты
- **Baseline**: Большинство рабочих нагрузок приложений
- **Restricted**: Безопасно-чувствительные приложения

## Архитектура хранилища

### Классы хранилищ по сети
- **local-storage**: Локальное хранилище узла (по умолчанию)
- **ssd-storage**: Хранилище на основе SSD (192.168.2.0/24)
- **hdd-storage**: Хранилище на основе HDD (192.168.3.0/24, 192.168.4.0/24)
- **nfs-storage**: Сетевая файловая система (192.168.5.0/24)

### Persistent Volumes
- **Jenkins**: 50GB локальное хранилище (192.168.2.0/24)
- **Grafana**: 10GB локальное хранилище (192.168.2.0/24)
- **Artifactory**: 100GB локальное хранилище (192.168.2.0/24)
- **Monitoring**: 20GB локальное хранилище (192.168.2.0/24)

## Архитектура мониторинга

### Сбор метрик
- **Node Exporter**: Метрики уровня узла
- **kube-state-metrics**: Метрики объектов Kubernetes
- **Prometheus**: Хранение и запрос метрик
- **Grafana**: Визуализация метрик

### Логирование
- **Fluentd**: Сбор логов
- **Elasticsearch**: Хранение логов
- **Kibana**: Визуализация логов

### Алертинг
- **AlertManager**: Маршрутизация и группировка алертов
- **Prometheus**: Оценка правил алертов
- **Grafana**: Визуализация алертов 