# Requirements / Требования

[English](#english) | [Русский](#russian)

## English

### System Requirements

#### Hardware Requirements

##### Minimum Requirements

**Control Plane Nodes:**
- CPU: 2 cores (x86_64)
- RAM: 4GB
- Storage: 50GB SSD
- Network: 1Gbps

**Worker Nodes:**
- CPU: 2 cores (x86_64)
- RAM: 4GB
- Storage: 100GB SSD
- Network: 1Gbps

**Load Balancer:**
- CPU: 1 core (x86_64)
- RAM: 2GB
- Storage: 20GB SSD
- Network: 1Gbps

##### Recommended Requirements

**Control Plane Nodes:**
- CPU: 4 cores (x86_64)
- RAM: 8GB
- Storage: 100GB NVMe SSD
- Network: 10Gbps

**Worker Nodes:**
- CPU: 8 cores (x86_64)
- RAM: 16GB
- Storage: 500GB NVMe SSD
- Network: 10Gbps

**Load Balancer:**
- CPU: 2 cores (x86_64)
- RAM: 4GB
- Storage: 50GB SSD
- Network: 10Gbps

#### Software Requirements

##### Operating System
- Ubuntu 20.04 LTS or 22.04 LTS
- CentOS 8/Rocky Linux 8
- RHEL 8/9

##### Required Software

**Management Node:**
- Terraform >= 1.0
- Ansible >= 2.9
- kubectl >= 1.24
- SSH client
- Git

**Target Nodes:**
- Docker >= 20.10
- containerd >= 1.6
- Systemd
- iptables
- ipset

#### Network Requirements

##### Network Configuration
- Static IP addresses for all nodes
- DNS resolution for all nodes
- Network connectivity between all nodes
- Firewall rules configured appropriately

##### Port Requirements

**Control Plane:**
- 6443: Kubernetes API Server
- 2379-2380: etcd
- 10250: Kubelet API
- 10251: kube-scheduler
- 10252: kube-controller-manager

**Worker Nodes:**
- 10250: Kubelet API
- 30000-32767: NodePort Services

**Load Balancer:**
- 6443: Kubernetes API Server (forwarded)
- 80: HTTP
- 443: HTTPS

## Русский

### Системные требования

#### Требования к оборудованию

##### Минимальные требования

**Control Plane узлы:**
- CPU: 2 ядра (x86_64)
- RAM: 4GB
- Хранилище: 50GB SSD
- Сеть: 1Gbps

**Worker узлы:**
- CPU: 2 ядра (x86_64)
- RAM: 4GB
- Хранилище: 100GB SSD
- Сеть: 1Gbps

**Балансировщик нагрузки:**
- CPU: 1 ядро (x86_64)
- RAM: 2GB
- Хранилище: 20GB SSD
- Сеть: 1Gbps

##### Рекомендуемые требования

**Control Plane узлы:**
- CPU: 4 ядра (x86_64)
- RAM: 8GB
- Хранилище: 100GB NVMe SSD
- Сеть: 10Gbps

**Worker узлы:**
- CPU: 8 ядер (x86_64)
- RAM: 16GB
- Хранилище: 500GB NVMe SSD
- Сеть: 10Gbps

**Балансировщик нагрузки:**
- CPU: 2 ядра (x86_64)
- RAM: 4GB
- Хранилище: 50GB SSD
- Сеть: 10Gbps

#### Требования к программному обеспечению

##### Операционная система
- Ubuntu 20.04 LTS или 22.04 LTS
- CentOS 8/Rocky Linux 8
- RHEL 8/9

##### Необходимое программное обеспечение

**Узел управления:**
- Terraform >= 1.0
- Ansible >= 2.9
- kubectl >= 1.24
- SSH клиент
- Git

**Целевые узлы:**
- Docker >= 20.10
- containerd >= 1.6
- Systemd
- iptables
- ipset

#### Сетевые требования

##### Сетевая конфигурация
- Статические IP адреса для всех узлов
- DNS разрешение для всех узлов
- Сетевая связность между всеми узлами
- Правильно настроенные правила файрвола

##### Требования к портам

**Control Plane:**
- 6443: Kubernetes API Server
- 2379-2380: etcd
- 10250: Kubelet API
- 10251: kube-scheduler
- 10252: kube-controller-manager

**Worker узлы:**
- 10250: Kubelet API
- 30000-32767: NodePort Services

**Балансировщик нагрузки:**
- 6443: Kubernetes API Server (проксирование)
- 80: HTTP
- 443: HTTPS

### Дополнительные требования

#### Безопасность
- SSH ключи настроены для всех узлов
- Файрвол настроен и активен
- SELinux/AppArmor настроены (если используется)
- Регулярные обновления безопасности

#### Мониторинг
- Доступ к метрикам системы
- Логирование всех компонентов
- Алертинг при проблемах
- Резервное копирование конфигураций

#### Масштабируемость
- Возможность добавления новых узлов
- Горизонтальное масштабирование
- Вертикальное масштабирование ресурсов
- Балансировка нагрузки 