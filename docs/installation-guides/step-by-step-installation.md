# Step-by-Step Installation Guide
# Пошаговое руководство по установке

[English](#english) | [Русский](#russian)

## English

### Prerequisites

#### Hardware Requirements

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

### Step 5: Choose and Install CNI Plugin

#### 5.1 CNI Selection Guide

Before installing a CNI plugin, consider your requirements:

**For Development/Lab Environment:**
- **Recommendation**: Flannel
- **Reason**: Simple, reliable, easy to troubleshoot

**For Small Production Cluster:**
- **Recommendation**: Calico
- **Reason**: Good balance of features and complexity

**For Enterprise Production:**
- **Recommendation**: Calico or Cilium
- **Reason**: Advanced security and monitoring capabilities

**For High-Performance Requirements:**
- **Recommendation**: Cilium
- **Reason**: eBPF-based performance and L7 policies

#### 5.2 Install CNI Using Automated Script

```bash
# Make the script executable
chmod +x src/scripts/deploy-cni.sh

# Deploy Flannel (recommended for labs)
./src/scripts/deploy-cni.sh flannel --verify

# OR Deploy Calico (recommended for production)
./src/scripts/deploy-cni.sh calico --force --verify

# OR Deploy Cilium (for high performance)
./src/scripts/deploy-cni.sh cilium --force --verify

# OR Deploy Weave (for simple deployments)
./src/scripts/deploy-cni.sh weave --verify
```

#### 5.3 Manual CNI Installation

**Flannel (Simple and Reliable):**
```bash
# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Verify installation
kubectl get pods -n kube-flannel
```

**Calico (Enterprise-Grade Security):**
```bash
# Install Calico
kubectl apply -f src/kubernetes/network/calico/calico-install.yaml

# Verify installation
kubectl get pods -n calico-system
```

**Cilium (Next-Generation eBPF):**
```bash
# Check kernel version (requires 4.9+)
uname -r

# Install Cilium
kubectl apply -f src/kubernetes/network/cilium/cilium-install.yaml

# Verify installation
kubectl get pods -n cilium
```

**Weave (Simple and Autonomous):**
```bash
# Install Weave
kubectl apply -f https://github.com/weaveworks/weave/releases/download/latest_release/weave-daemonset-k8s.yaml

# Verify installation
kubectl get pods -n kube-system -l name=weave-net
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

### Step 6: Join Worker Nodes

#### 6.1 Join Worker Nodes
```bash
# On each worker node, run the join command
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

#### 6.2 Verify Node Join
```bash
# Check node status
kubectl get nodes

# Check node labels
kubectl get nodes --show-labels
```

### Step 7: Configure Node Labels and Taints

#### 7.1 Label Nodes
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

kubectl label nodes k8s-worker-small-01 storage-type=hdd
kubectl label nodes k8s-worker-small-02 storage-type=hdd
kubectl label nodes k8s-worker-small-03 storage-type=hdd
```

#### 7.2 Configure Taints
```bash
# Taint control plane nodes
kubectl taint nodes k8s-master-01 node-role.kubernetes.io/control-plane=true:NoSchedule
kubectl taint nodes k8s-master-02 node-role.kubernetes.io/control-plane=true:NoSchedule
kubectl taint nodes k8s-master-03 node-role.kubernetes.io/control-plane=true:NoSchedule

# Taint worker nodes for specific workloads
kubectl taint nodes k8s-worker-big-01 dedicated=jenkins:NoSchedule
kubectl taint nodes k8s-worker-big-02 dedicated=monitoring:NoSchedule
kubectl taint nodes k8s-worker-big-03 dedicated=gitops:NoSchedule
```

### Step 8: Deploy Additional Components

#### 8.1 Deploy Storage Classes
```bash
# Deploy local storage
kubectl apply -f src/kubernetes/storage/storage-classes.yaml

# Verify storage classes
kubectl get storageclass
```

#### 8.2 Deploy Load Balancer (MetalLB)
```bash
# Deploy MetalLB
kubectl apply -f src/kubernetes/network/metallb-config.yaml

# Verify MetalLB
kubectl get pods -n metallb-system
```

#### 8.3 Deploy Ingress Controller
```bash
# Deploy NGINX Ingress Controller
kubectl apply -f src/kubernetes/ingress/nginx-ingress.yaml

# Verify Ingress Controller
kubectl get pods -n ingress-nginx
```

### Step 9: Deploy Applications

#### 9.1 Deploy Monitoring Stack
```bash
# Deploy monitoring components
./src/scripts/deploy-monitoring.sh
```

#### 9.2 Deploy Lab Applications
```bash
# Deploy lab applications
./src/scripts/deploy-lab-stands.sh
```

#### 9.3 Deploy Security Components
```bash
# Deploy security components
./src/scripts/deploy-security.sh
```

### Step 10: Verify Installation

#### 10.1 Check Cluster Health
```bash
# Check all nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods --all-namespaces

# Check cluster info
kubectl cluster-info

# Check component status
kubectl get componentstatuses
```

#### 10.2 Test Network Connectivity
```bash
# Test pod-to-pod communication
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Test service connectivity
kubectl run test-service --image=busybox --rm -it --restart=Never -- wget -qO- http://kubernetes.default
```

#### 10.3 Test Storage
```bash
# Create test PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
EOF

# Verify PVC
kubectl get pvc
```

## Русский

### Предварительные требования

#### Требования к оборудованию

#### Узлы Control Plane (3x)
- **CPU**: минимум 4 ядра, рекомендуется 8 ядер
- **RAM**: минимум 8GB, рекомендуется 16GB
- **Хранилище**: минимум 100GB, рекомендуется SSD
- **Сеть**: минимум 1Gbps

#### Worker узлы (9x)
- **Большие узлы (3x)**: 8 CPU, 16GB RAM, 500GB SSD
- **Средние узлы (3x)**: 4 CPU, 8GB RAM, 250GB HDD
- **Малые узлы (3x)**: 2 CPU, 4GB RAM, 100GB HDD

#### Load Balancer
- **CPU**: минимум 2 ядра
- **RAM**: минимум 4GB
- **Хранилище**: минимум 50GB
- **Сеть**: минимум 1Gbps

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

### Шаг 5: Выбор и установка CNI плагина

#### 5.1 Руководство по выбору CNI

Перед установкой CNI плагина рассмотрите ваши требования:

**Для среды разработки/Лаборатории:**
- **Рекомендация**: Flannel
- **Причина**: Простой, надежный, легко диагностировать

**Для небольшого продакшен кластера:**
- **Рекомендация**: Calico
- **Причина**: Хороший баланс функций и сложности

**Для Enterprise продакшена:**
- **Рекомендация**: Calico или Cilium
- **Причина**: Продвинутые возможности безопасности и мониторинга

**Для требований высокой производительности:**
- **Рекомендация**: Cilium
- **Причина**: Производительность на основе eBPF и L7 политики

#### 5.2 Установка CNI с помощью автоматизированного скрипта

```bash
# Сделать скрипт исполняемым
chmod +x src/scripts/deploy-cni.sh

# Развернуть Flannel (рекомендуется для лабораторий)
./src/scripts/deploy-cni.sh flannel --verify

# ИЛИ Развернуть Calico (рекомендуется для продакшена)
./src/scripts/deploy-cni.sh calico --force --verify

# ИЛИ Развернуть Cilium (для высокой производительности)
./src/scripts/deploy-cni.sh cilium --force --verify

# ИЛИ Развернуть Weave (для простых развертываний)
./src/scripts/deploy-cni.sh weave --verify
```

#### 5.3 Ручная установка CNI

**Flannel (Простой и надежный):**
```bash
# Установка Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Проверка установки
kubectl get pods -n kube-flannel
```

**Calico (Enterprise-уровень безопасности):**
```bash
# Установка Calico
kubectl apply -f src/kubernetes/network/calico/calico-install.yaml

# Проверка установки
kubectl get pods -n calico-system
```

**Cilium (Сетевое взаимодействие нового поколения eBPF):**
```bash
# Проверка версии ядра (требуется 4.9+)
uname -r

# Установка Cilium
kubectl apply -f src/kubernetes/network/cilium/cilium-install.yaml

# Проверка установки
kubectl get pods -n cilium
```

**Weave (Простой и автономный):**
```bash
# Установка Weave
kubectl apply -f https://github.com/weaveworks/weave/releases/download/latest_release/weave-daemonset-k8s.yaml

# Проверка установки
kubectl get pods -n kube-system -l name=weave-net
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

### Шаг 6: Подключение Worker узлов

#### 6.1 Подключение Worker узлов
```bash
# На каждом worker узле выполните команду join
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

#### 6.2 Проверка подключения узлов
```bash
# Проверка статуса узлов
kubectl get nodes

# Проверка меток узлов
kubectl get nodes --show-labels
```

### Шаг 7: Настройка меток и taint узлов

#### 7.1 Метки узлов
```bash
# Метки узлов control plane
kubectl label nodes k8s-master-01 node-role.kubernetes.io/control-plane=true
kubectl label nodes k8s-master-02 node-role.kubernetes.io/control-plane=true
kubectl label nodes k8s-master-03 node-role.kubernetes.io/control-plane=true

# Метки worker узлов по типу
kubectl label nodes k8s-worker-big-01 node-type=big
kubectl label nodes k8s-worker-big-02 node-type=big
kubectl label nodes k8s-worker-big-03 node-type=big

kubectl label nodes k8s-worker-medium-01 node-type=medium
kubectl label nodes k8s-worker-medium-02 node-type=medium
kubectl label nodes k8s-worker-medium-03 node-type=medium

kubectl label nodes k8s-worker-small-01 node-type=small
kubectl label nodes k8s-worker-small-02 node-type=small
kubectl label nodes k8s-worker-small-03 node-type=small

# Метки по типу хранилища
kubectl label nodes k8s-worker-big-01 storage-type=ssd
kubectl label nodes k8s-worker-big-02 storage-type=ssd
kubectl label nodes k8s-worker-big-03 storage-type=ssd

kubectl label nodes k8s-worker-medium-01 storage-type=hdd
kubectl label nodes k8s-worker-medium-02 storage-type=hdd
kubectl label nodes k8s-worker-medium-03 storage-type=hdd

kubectl label nodes k8s-worker-small-01 storage-type=hdd
kubectl label nodes k8s-worker-small-02 storage-type=hdd
kubectl label nodes k8s-worker-small-03 storage-type=hdd
```

#### 7.2 Настройка taint
```bash
# Taint узлов control plane
kubectl taint nodes k8s-master-01 node-role.kubernetes.io/control-plane=true:NoSchedule
kubectl taint nodes k8s-master-02 node-role.kubernetes.io/control-plane=true:NoSchedule
kubectl taint nodes k8s-master-03 node-role.kubernetes.io/control-plane=true:NoSchedule

# Taint worker узлов для специфических нагрузок
kubectl taint nodes k8s-worker-big-01 dedicated=jenkins:NoSchedule
kubectl taint nodes k8s-worker-big-02 dedicated=monitoring:NoSchedule
kubectl taint nodes k8s-worker-big-03 dedicated=gitops:NoSchedule
```

### Шаг 8: Развертывание дополнительных компонентов

#### 8.1 Развертывание Storage Classes
```bash
# Развертывание локального хранилища
kubectl apply -f src/kubernetes/storage/storage-classes.yaml

# Проверка storage classes
kubectl get storageclass
```

#### 8.2 Развертывание Load Balancer (MetalLB)
```bash
# Развертывание MetalLB
kubectl apply -f src/kubernetes/network/metallb-config.yaml

# Проверка MetalLB
kubectl get pods -n metallb-system
```

#### 8.3 Развертывание Ingress Controller
```bash
# Развертывание NGINX Ingress Controller
kubectl apply -f src/kubernetes/ingress/nginx-ingress.yaml

# Проверка Ingress Controller
kubectl get pods -n ingress-nginx
```

### Шаг 9: Развертывание приложений

#### 9.1 Развертывание стека мониторинга
```bash
# Развертывание компонентов мониторинга
./src/scripts/deploy-monitoring.sh
```

#### 9.2 Развертывание лабораторных приложений
```bash
# Развертывание лабораторных приложений
./src/scripts/deploy-lab-stands.sh
```

#### 9.3 Развертывание компонентов безопасности
```bash
# Развертывание компонентов безопасности
./src/scripts/deploy-security.sh
```

### Шаг 10: Проверка установки

#### 10.1 Проверка здоровья кластера
```bash
# Проверка всех узлов
kubectl get nodes -o wide

# Проверка всех подов
kubectl get pods --all-namespaces

# Проверка информации о кластере
kubectl cluster-info

# Проверка статуса компонентов
kubectl get componentstatuses
```

#### 10.2 Тестирование сетевого подключения
```bash
# Тестирование связи под-к-под
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Тестирование подключения к сервисам
kubectl run test-service --image=busybox --rm -it --restart=Never -- wget -qO- http://kubernetes.default
```

#### 10.3 Тестирование хранилища
```bash
# Создание тестового PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
EOF

# Проверка PVC
kubectl get pvc
``` 