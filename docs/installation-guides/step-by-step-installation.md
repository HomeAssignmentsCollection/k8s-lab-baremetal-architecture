# Step-by-Step Installation Guide / Пошаговое руководство по установке

[English](#english) | [Русский](#russian)

## English

### Prerequisites

Before starting the installation, ensure you have:
- Bare metal servers with Ubuntu 20.04/22.04 or CentOS 8/Rocky Linux 8
- Network connectivity between all nodes
- SSH access to all servers
- Root or sudo privileges

### Master Node Installation

#### Step 1: System Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# OR
sudo yum update -y  # CentOS/Rocky Linux

# Install required packages
sudo apt install -y curl wget git vim htop net-tools  # Ubuntu/Debian
# OR
sudo yum install -y curl wget git vim htop net-tools  # CentOS/Rocky Linux

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

#### Step 2: Install Container Runtime

```bash
# Install containerd
sudo apt install -y containerd  # Ubuntu/Debian
# OR
sudo yum install -y containerd  # CentOS/Rocky Linux

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable and start containerd
sudo systemctl enable containerd
sudo systemctl start containerd
```

#### Step 3: Install Kubernetes Components

```bash
# Add Kubernetes repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list and install Kubernetes
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Hold packages to prevent automatic updates
sudo apt-mark hold kubelet kubeadm kubectl
```

#### Step 4: Initialize Kubernetes Cluster

```bash
# Initialize the cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<MASTER_IP>

# Set up kubectl for your user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI plugin (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

#### Step 5: Join Additional Master Nodes (for HA)

```bash
# On the first master, create a new token
sudo kubeadm token create --print-join-command

# On additional master nodes, run the join command with --control-plane flag
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH> --control-plane
```

### Worker Node Installation

#### Step 1: System Preparation (Same as Master)

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git vim htop net-tools

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

#### Step 2: Install Container Runtime (Same as Master)

```bash
# Install containerd
sudo apt install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable and start containerd
sudo systemctl enable containerd
sudo systemctl start containerd
```

#### Step 3: Install Kubernetes Components (Same as Master)

```bash
# Add Kubernetes repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list and install Kubernetes
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Hold packages to prevent automatic updates
sudo apt-mark hold kubelet kubeadm kubectl
```

#### Step 4: Join Worker Node to Cluster

```bash
# Get join command from master node
# On master node:
sudo kubeadm token create --print-join-command

# On worker node, run the join command:
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### Verification

```bash
# On master node, verify cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check node roles
kubectl get nodes -o wide
```

## Русский

### Предварительные требования

Перед началом установки убедитесь, что у вас есть:
- Bare metal серверы с Ubuntu 20.04/22.04 или CentOS 8/Rocky Linux 8
- Сетевая связность между всеми узлами
- SSH доступ ко всем серверам
- Root или sudo привилегии

### Установка Master узла

#### Шаг 1: Подготовка системы

```bash
# Обновление системных пакетов
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# ИЛИ
sudo yum update -y  # CentOS/Rocky Linux

# Установка необходимых пакетов
sudo apt install -y curl wget git vim htop net-tools  # Ubuntu/Debian
# ИЛИ
sudo yum install -y curl wget git vim htop net-tools  # CentOS/Rocky Linux

# Отключение swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Загрузка модулей ядра
sudo modprobe overlay
sudo modprobe br_netfilter

# Настройка sysctl
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

#### Шаг 2: Установка Container Runtime

```bash
# Установка containerd
sudo apt install -y containerd  # Ubuntu/Debian
# ИЛИ
sudo yum install -y containerd  # CentOS/Rocky Linux

# Настройка containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Включение и запуск containerd
sudo systemctl enable containerd
sudo systemctl start containerd
```

#### Шаг 3: Установка компонентов Kubernetes

```bash
# Добавление репозитория Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Обновление списка пакетов и установка Kubernetes
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Блокировка пакетов для предотвращения автоматических обновлений
sudo apt-mark hold kubelet kubeadm kubectl
```

#### Шаг 4: Инициализация кластера Kubernetes

```bash
# Инициализация кластера
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<MASTER_IP>

# Настройка kubectl для пользователя
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Установка CNI плагина (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

#### Шаг 5: Присоединение дополнительных Master узлов (для HA)

```bash
# На первом master узле создайте новый токен
sudo kubeadm token create --print-join-command

# На дополнительных master узлах выполните команду join с флагом --control-plane
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH> --control-plane
```

### Установка Worker узла

#### Шаг 1: Подготовка системы (аналогично Master)

```bash
# Обновление системных пакетов
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl wget git vim htop net-tools

# Отключение swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Загрузка модулей ядра
sudo modprobe overlay
sudo modprobe br_netfilter

# Настройка sysctl
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

#### Шаг 2: Установка Container Runtime (аналогично Master)

```bash
# Установка containerd
sudo apt install -y containerd

# Настройка containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Включение и запуск containerd
sudo systemctl enable containerd
sudo systemctl start containerd
```

#### Шаг 3: Установка компонентов Kubernetes (аналогично Master)

```bash
# Добавление репозитория Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Обновление списка пакетов и установка Kubernetes
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Блокировка пакетов для предотвращения автоматических обновлений
sudo apt-mark hold kubelet kubeadm kubectl
```

#### Шаг 4: Присоединение Worker узла к кластеру

```bash
# Получите команду join с master узла
# На master узле:
sudo kubeadm token create --print-join-command

# На worker узле выполните команду join:
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### Проверка

```bash
# На master узле проверьте статус кластера
kubectl get nodes
kubectl get pods --all-namespaces

# Проверьте роли узлов
kubectl get nodes -o wide
```

### Troubleshooting

#### Common Issues

1. **Node not joining cluster**
   - Check network connectivity
   - Verify firewall rules
   - Check token expiration

2. **Pods stuck in Pending**
   - Check node resources
   - Verify CNI plugin installation
   - Check node taints

3. **API server not accessible**
   - Check kubelet status
   - Verify certificate configuration
   - Check load balancer configuration 