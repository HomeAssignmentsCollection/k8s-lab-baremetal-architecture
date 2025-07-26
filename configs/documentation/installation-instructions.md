# Installation Instructions / Инструкции по установке

[English](#english) | [Русский](#russian)

## English

This document provides step-by-step instructions for installing and configuring the Kubernetes Baremetal Lab project.

## Prerequisites

### Hardware Requirements

#### Control Plane Nodes (3x)
- **CPU**: 4 cores minimum, 8 cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 100GB minimum, SSD recommended
- **Network**: 1Gbps minimum

#### Worker Nodes (9x)
- **Big Nodes (3x)**: 8 CPU, 16GB RAM, 500GB SSD
- **Medium Nodes (3x)**: 4 CPU, 8GB RAM, 250GB HDD
- **Small Nodes (3x)**: 2 CPU, 4GB RAM, 100GB HDD

#### Load Balancer
- **CPU**: 2 cores minimum
- **RAM**: 4GB minimum
- **Storage**: 50GB minimum
- **Network**: 1Gbps minimum

### Software Requirements

#### Operating System
- **Recommended**: Ubuntu 22.04 LTS
- **Alternative**: CentOS 8, RHEL 8, Debian 11

#### Required Software
- **Docker**: 20.10+ or containerd 1.6+
- **Kubernetes**: 1.28.0
- **Terraform**: 1.5+
- **Ansible**: 2.15+
- **kubectl**: 1.28.0

## Installation Steps

### Step 1: Prepare Infrastructure

#### 1.1 Network Configuration
```bash
# Configure network interfaces
sudo nano /etc/netplan/01-netcfg.yaml

# Example configuration
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:
      dhcp4: no
      addresses:
        - 192.168.1.10/24  # Control plane node 1
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Apply network configuration
sudo netplan apply
```

#### 1.2 System Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  python3 \
  python3-pip \
  git \
  wget \
  unzip

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### Step 2: Install Container Runtime

#### 2.1 Install containerd
```bash
# Install containerd
sudo apt install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### Step 3: Install Kubernetes Components

#### 3.1 Add Kubernetes Repository
```bash
# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list
sudo apt update
```

#### 3.2 Install Kubernetes Components
```bash
# Install kubeadm, kubelet, and kubectl
sudo apt install -y kubelet kubeadm kubectl

# Hold packages to prevent automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable kubelet
```

### Step 4: Initialize Kubernetes Cluster

#### 4.1 Initialize First Control Plane Node
```bash
# Generate configuration
./configs/scripts/generate-config.sh dev

# Initialize cluster
sudo kubeadm init \
  --config=/tmp/kubeadm-config.yaml \
  --upload-certs \
  --control-plane-endpoint=192.168.1.100:6443 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### 4.2 Install CNI Plugin (Flannel)
```bash
# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Verify installation
kubectl get pods -n kube-flannel
```

#### 4.3 Join Additional Control Plane Nodes
```bash
# On additional control plane nodes, run the join command from step 4.1
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>
```

### Step 5: Join Worker Nodes

#### 5.1 Join Worker Nodes
```bash
# On each worker node, run the join command
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

#### 5.2 Verify Node Join
```bash
# Check node status
kubectl get nodes

# Check node labels
kubectl get nodes --show-labels
```

### Step 6: Configure Node Labels and Taints

#### 6.1 Label Nodes
```bash
# Label control plane nodes
kubectl label nodes k8s-master-01 node-role.kubernetes.io/control-plane=true
kubectl label nodes k8s-master-02 node-role.kubernetes.io/control-plane=true
kubectl label nodes k8s-master-03 node-role.kubernetes.io/control-plane=true

# Label worker nodes by type
kubectl label nodes k8s-worker-big-01 node-type=big
kubectl label nodes k8s-worker-big-02 node-type=big
kubectl label nodes k8s-worker-big-03 node-type=big

kubectl label nodes k8s-worker-medium-01 node-type=medium
kubectl label nodes k8s-worker-medium-02 node-type=medium
kubectl label nodes k8s-worker-medium-03 node-type=medium

kubectl label nodes k8s-worker-small-01 node-type=small
kubectl label nodes k8s-worker-small-02 node-type=small
kubectl label nodes k8s-worker-small-03 node-type=small

# Label by storage type
kubectl label nodes k8s-worker-big-01 storage-type=ssd
kubectl label nodes k8s-worker-big-02 storage-type=ssd
kubectl label nodes k8s-worker-big-03 storage-type=ssd

kubectl label nodes k8s-worker-medium-01 storage-type=hdd
kubectl label nodes k8s-worker-medium-02 storage-type=hdd
kubectl label nodes k8s-worker-medium-03 storage-type=hdd
```

#### 6.2 Apply Taints
```bash
# Apply taints for dedicated workloads
kubectl taint nodes k8s-worker-big-01 dedicated=jenkins:NoSchedule
kubectl taint nodes k8s-worker-big-02 dedicated=monitoring:NoSchedule
kubectl taint nodes k8s-worker-big-03 dedicated=artifacts:NoSchedule
```

### Step 7: Deploy Infrastructure Components

#### 7.1 Deploy Storage Classes
```bash
# Deploy storage classes
kubectl apply -f src/kubernetes/storage/storage-classes.yaml

# Verify storage classes
kubectl get storageclass
```

#### 7.2 Deploy MetalLB
```bash
# Deploy MetalLB
kubectl apply -f src/kubernetes/network/metallb-config.yaml

# Verify MetalLB installation
kubectl get pods -n metallb-system
```

#### 7.3 Deploy Ingress Controller
```bash
# Deploy NGINX Ingress Controller
kubectl apply -f src/kubernetes/network/ingress-config.yaml

# Verify ingress controller
kubectl get pods -n ingress-nginx
```

### Step 8: Deploy Applications

#### 8.1 Deploy with YAML Manifests
```bash
# Deploy all applications
./src/scripts/deploy-all.sh

# Verify deployments
kubectl get pods --all-namespaces
```

#### 8.2 Deploy with Helm Charts
```bash
# Deploy with Helm
./src/scripts/deploy-helm.sh

# Verify deployments
kubectl get pods --all-namespaces
```

### Step 9: Configure Applications

#### 9.1 Configure Jenkins
```bash
# Get Jenkins admin password
kubectl exec -n jenkins deployment/jenkins -- cat /run/secrets/additional/chart-admin-password

# Access Jenkins UI
# http://192.168.1.201:8080
```

#### 9.2 Configure ArgoCD
```bash
# Get ArgoCD admin password
kubectl -n gitops get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI
# http://192.168.1.202
```

#### 9.3 Configure Grafana
```bash
# Get Grafana admin password
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Access Grafana UI
# http://192.168.1.203:3000
```

### Step 10: Verification and Testing

#### 10.1 Run Health Checks
```bash
# Run cluster health check
./src/utils/cluster-health-check.sh

# Run manifest tests
./test/test-manifests.sh
```

#### 10.2 Verify Services
```bash
# Check all services
kubectl get svc --all-namespaces

# Test service connectivity
curl -I http://192.168.1.201:8080  # Jenkins
curl -I http://192.168.1.202       # ArgoCD
curl -I http://192.168.1.203:3000  # Grafana
```

## Troubleshooting

### Common Issues

#### 1. Node Not Ready
```bash
# Check node status
kubectl describe node <node-name>

# Check kubelet logs
sudo journalctl -u kubelet -f

# Check container runtime
sudo systemctl status containerd
```

#### 2. Pod Stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl describe node <node-name>

# Check storage
kubectl get pv,pvc --all-namespaces
```

#### 3. Network Issues
```bash
# Check CNI pods
kubectl get pods -n kube-flannel

# Check network policies
kubectl get networkpolicy --all-namespaces

# Test pod connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

#### 4. Storage Issues
```bash
# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv

# Check persistent volume claims
kubectl get pvc --all-namespaces
```

### Recovery Procedures

#### 1. Reset Failed Node
```bash
# Drain node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Reset kubeadm
sudo kubeadm reset

# Rejoin cluster
sudo kubeadm join <control-plane-endpoint> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

#### 2. Backup and Restore
```bash
# Backup etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/etcd-backup.db

# Restore etcd
sudo kubeadm reset
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot restore /tmp/etcd-backup.db
```

## Post-Installation

### 1. Security Hardening
```bash
# Enable RBAC
kubectl apply -f src/kubernetes/security/rbac-config.yaml

# Apply network policies
kubectl apply -f src/kubernetes/security/network-policies.yaml

# Configure pod security standards
kubectl apply -f src/kubernetes/security/pod-security-standards.yaml
```

### 2. Monitoring Setup
```bash
# Deploy monitoring stack
kubectl apply -f src/kubernetes/monitoring/

# Configure dashboards
kubectl apply -f src/kubernetes/monitoring/grafana/dashboards/

# Set up alerting
kubectl apply -f src/kubernetes/monitoring/alertmanager/
```

### 3. Backup Configuration
```bash
# Create backup script
cat > /usr/local/bin/k8s-backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/k8s/$DATE"
mkdir -p $BACKUP_DIR

# Backup etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save $BACKUP_DIR/etcd-backup.db

# Backup manifests
kubectl get all --all-namespaces -o yaml > $BACKUP_DIR/manifests.yaml

# Backup configs
cp -r /etc/kubernetes $BACKUP_DIR/
cp -r ~/.kube $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x /usr/local/bin/k8s-backup.sh

# Add to crontab
echo "0 2 * * * /usr/local/bin/k8s-backup.sh" | sudo crontab -
```

## Русский

Этот документ предоставляет пошаговые инструкции по установке и настройке проекта Kubernetes Baremetal Lab.

## Предварительные требования

### Требования к оборудованию

#### Узлы Control Plane (3x)
- **CPU**: 4 ядра минимум, 8 ядер рекомендуется
- **RAM**: 8GB минимум, 16GB рекомендуется
- **Хранилище**: 100GB минимум, SSD рекомендуется
- **Сеть**: 1Gbps минимум

#### Worker узлы (9x)
- **Большие узлы (3x)**: 8 CPU, 16GB RAM, 500GB SSD
- **Средние узлы (3x)**: 4 CPU, 8GB RAM, 250GB HDD
- **Малые узлы (3x)**: 2 CPU, 4GB RAM, 100GB HDD

#### Load Balancer
- **CPU**: 2 ядра минимум
- **RAM**: 4GB минимум
- **Хранилище**: 50GB минимум
- **Сеть**: 1Gbps минимум

### Требования к программному обеспечению

#### Операционная система
- **Рекомендуется**: Ubuntu 22.04 LTS
- **Альтернатива**: CentOS 8, RHEL 8, Debian 11

#### Необходимое ПО
- **Docker**: 20.10+ или containerd 1.6+
- **Kubernetes**: 1.28.0
- **Terraform**: 1.5+
- **Ansible**: 2.15+
- **kubectl**: 1.28.0

## Шаги установки

### Шаг 1: Подготовка инфраструктуры

#### 1.1 Настройка сети
```bash
# Настройка сетевых интерфейсов
sudo nano /etc/netplan/01-netcfg.yaml

# Пример конфигурации
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:
      dhcp4: no
      addresses:
        - 192.168.1.10/24  # Control plane узел 1
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Применение сетевой конфигурации
sudo netplan apply
```

#### 1.2 Подготовка системы
```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  python3 \
  python3-pip \
  git \
  wget \
  unzip

# Отключение swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Загрузка модулей ядра
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Настройка sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### Шаг 2: Установка Container Runtime

#### 2.1 Установка containerd
```bash
# Установка containerd
sudo apt install -y containerd

# Настройка containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Включение systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Перезапуск containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### Шаг 3: Установка компонентов Kubernetes

#### 3.1 Добавление репозитория Kubernetes
```bash
# Добавление GPG ключа Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Добавление репозитория Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Обновление списка пакетов
sudo apt update
```

#### 3.2 Установка компонентов Kubernetes
```bash
# Установка kubeadm, kubelet, и kubectl
sudo apt install -y kubelet kubeadm kubectl

# Блокировка пакетов для предотвращения автоматических обновлений
sudo apt-mark hold kubelet kubeadm kubectl

# Включение kubelet
sudo systemctl enable kubelet
```

### Шаг 4: Инициализация кластера Kubernetes

#### 4.1 Инициализация первого узла Control Plane
```bash
# Генерация конфигурации
./configs/scripts/generate-config.sh dev

# Инициализация кластера
sudo kubeadm init \
  --config=/tmp/kubeadm-config.yaml \
  --upload-certs \
  --control-plane-endpoint=192.168.1.100:6443 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12

# Настройка kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### 4.2 Установка CNI плагина (Flannel)
```bash
# Установка Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Проверка установки
kubectl get pods -n kube-flannel
```

#### 4.3 Подключение дополнительных узлов Control Plane
```bash
# На дополнительных узлах Control Plane выполните команду join из шага 4.1
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>
```

### Шаг 5: Подключение Worker узлов

#### 5.1 Подключение Worker узлов
```bash
# На каждом worker узле выполните команду join
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

#### 5.2 Проверка подключения узлов
```bash
# Проверка статуса узлов
kubectl get nodes

# Проверка меток узлов
kubectl get nodes --show-labels
```

### Шаг 6: Настройка меток и taints узлов

#### 6.1 Маркировка узлов
```bash
# Маркировка узлов control plane
kubectl label nodes k8s-master-01 node-role.kubernetes.io/control-plane=true
kubectl label nodes k8s-master-02 node-role.kubernetes.io/control-plane=true
kubectl label nodes k8s-master-03 node-role.kubernetes.io/control-plane=true

# Маркировка worker узлов по типу
kubectl label nodes k8s-worker-big-01 node-type=big
kubectl label nodes k8s-worker-big-02 node-type=big
kubectl label nodes k8s-worker-big-03 node-type=big

kubectl label nodes k8s-worker-medium-01 node-type=medium
kubectl label nodes k8s-worker-medium-02 node-type=medium
kubectl label nodes k8s-worker-medium-03 node-type=medium

kubectl label nodes k8s-worker-small-01 node-type=small
kubectl label nodes k8s-worker-small-02 node-type=small
kubectl label nodes k8s-worker-small-03 node-type=small

# Маркировка по типу хранилища
kubectl label nodes k8s-worker-big-01 storage-type=ssd
kubectl label nodes k8s-worker-big-02 storage-type=ssd
kubectl label nodes k8s-worker-big-03 storage-type=ssd

kubectl label nodes k8s-worker-medium-01 storage-type=hdd
kubectl label nodes k8s-worker-medium-02 storage-type=hdd
kubectl label nodes k8s-worker-medium-03 storage-type=hdd
```

#### 6.2 Применение taints
```bash
# Применение taints для выделенных нагрузок
kubectl taint nodes k8s-worker-big-01 dedicated=jenkins:NoSchedule
kubectl taint nodes k8s-worker-big-02 dedicated=monitoring:NoSchedule
kubectl taint nodes k8s-worker-big-03 dedicated=artifacts:NoSchedule
```

### Шаг 7: Развертывание инфраструктурных компонентов

#### 7.1 Развертывание классов хранилищ
```bash
# Развертывание классов хранилищ
kubectl apply -f src/kubernetes/storage/storage-classes.yaml

# Проверка классов хранилищ
kubectl get storageclass
```

#### 7.2 Развертывание MetalLB
```bash
# Развертывание MetalLB
kubectl apply -f src/kubernetes/network/metallb-config.yaml

# Проверка установки MetalLB
kubectl get pods -n metallb-system
```

#### 7.3 Развертывание Ingress контроллера
```bash
# Развертывание NGINX Ingress контроллера
kubectl apply -f src/kubernetes/network/ingress-config.yaml

# Проверка ingress контроллера
kubectl get pods -n ingress-nginx
```

### Шаг 8: Развертывание приложений

#### 8.1 Развертывание с YAML манифестами
```bash
# Развертывание всех приложений
./src/scripts/deploy-all.sh

# Проверка развертываний
kubectl get pods --all-namespaces
```

#### 8.2 Развертывание с Helm чартами
```bash
# Развертывание с Helm
./src/scripts/deploy-helm.sh

# Проверка развертываний
kubectl get pods --all-namespaces
```

### Шаг 9: Настройка приложений

#### 9.1 Настройка Jenkins
```bash
# Получение пароля администратора Jenkins
kubectl exec -n jenkins deployment/jenkins -- cat /run/secrets/additional/chart-admin-password

# Доступ к UI Jenkins
# http://192.168.1.201:8080
```

#### 9.2 Настройка ArgoCD
```bash
# Получение пароля администратора ArgoCD
kubectl -n gitops get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Доступ к UI ArgoCD
# http://192.168.1.202
```

#### 9.3 Настройка Grafana
```bash
# Получение пароля администратора Grafana
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Доступ к UI Grafana
# http://192.168.1.203:3000
```

### Шаг 10: Проверка и тестирование

#### 10.1 Запуск проверок здоровья
```bash
# Запуск проверки здоровья кластера
./src/utils/cluster-health-check.sh

# Запуск тестов манифестов
./test/test-manifests.sh
```

#### 10.2 Проверка сервисов
```bash
# Проверка всех сервисов
kubectl get svc --all-namespaces

# Тестирование подключения сервисов
curl -I http://192.168.1.201:8080  # Jenkins
curl -I http://192.168.1.202       # ArgoCD
curl -I http://192.168.1.203:3000  # Grafana
```

## Устранение неполадок

### Общие проблемы

#### 1. Узел не готов
```bash
# Проверка статуса узла
kubectl describe node <node-name>

# Проверка логов kubelet
sudo journalctl -u kubelet -f

# Проверка container runtime
sudo systemctl status containerd
```

#### 2. Под завис в Pending
```bash
# Проверка событий пода
kubectl describe pod <pod-name> -n <namespace>

# Проверка ресурсов узла
kubectl describe node <node-name>

# Проверка хранилища
kubectl get pv,pvc --all-namespaces
```

#### 3. Сетевые проблемы
```bash
# Проверка CNI подов
kubectl get pods -n kube-flannel

# Проверка сетевых политик
kubectl get networkpolicy --all-namespaces

# Тестирование подключения подов
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

#### 4. Проблемы с хранилищем
```bash
# Проверка классов хранилищ
kubectl get storageclass

# Проверка persistent volumes
kubectl get pv

# Проверка persistent volume claims
kubectl get pvc --all-namespaces
```

### Процедуры восстановления

#### 1. Сброс неудачного узла
```bash
# Очистка узла
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Сброс kubeadm
sudo kubeadm reset

# Повторное подключение к кластеру
sudo kubeadm join <control-plane-endpoint> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

#### 2. Резервное копирование и восстановление
```bash
# Резервное копирование etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/etcd-backup.db

# Восстановление etcd
sudo kubeadm reset
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot restore /tmp/etcd-backup.db
```

## После установки

### 1. Усиление безопасности
```bash
# Включение RBAC
kubectl apply -f src/kubernetes/security/rbac-config.yaml

# Применение сетевых политик
kubectl apply -f src/kubernetes/security/network-policies.yaml

# Настройка стандартов безопасности подов
kubectl apply -f src/kubernetes/security/pod-security-standards.yaml
```

### 2. Настройка мониторинга
```bash
# Развертывание стека мониторинга
kubectl apply -f src/kubernetes/monitoring/

# Настройка дашбордов
kubectl apply -f src/kubernetes/monitoring/grafana/dashboards/

# Настройка алертинга
kubectl apply -f src/kubernetes/monitoring/alertmanager/
```

### 3. Конфигурация резервного копирования
```bash
# Создание скрипта резервного копирования
cat > /usr/local/bin/k8s-backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/k8s/$DATE"
mkdir -p $BACKUP_DIR

# Резервное копирование etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save $BACKUP_DIR/etcd-backup.db

# Резервное копирование манифестов
kubectl get all --all-namespaces -o yaml > $BACKUP_DIR/manifests.yaml

# Резервное копирование конфигураций
cp -r /etc/kubernetes $BACKUP_DIR/
cp -r ~/.kube $BACKUP_DIR/

echo "Резервное копирование завершено: $BACKUP_DIR"
EOF

chmod +x /usr/local/bin/k8s-backup.sh

# Добавление в crontab
echo "0 2 * * * /usr/local/bin/k8s-backup.sh" | sudo crontab -
``` 