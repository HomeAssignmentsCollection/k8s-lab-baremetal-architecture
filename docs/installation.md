# Installation Guide / Руководство по установке

[English](#english) | [Русский](#russian)

## English

### Prerequisites

Before starting the installation, ensure you have the following:

- **Hardware**: Bare metal servers meeting the minimum requirements
- **Network**: Proper network configuration with static IPs
- **Software**: 
  - Terraform >= 1.0
  - Ansible >= 2.9
  - kubectl >= 1.24
  - SSH access to all servers

### Installation Steps

#### Step 1: Clone and Setup

```bash
git clone <repository-url>
cd k8s-lab-baremetal-architecture
```

#### Step 2: Configure Infrastructure

1. Navigate to the Terraform directory:
```bash
cd src/terraform
```

2. Copy and modify the configuration:
```bash
cp configs/terraform.tfvars.example configs/terraform.tfvars
# Edit the configuration with your environment details
```

3. Initialize and apply Terraform:
```bash
terraform init
terraform plan
terraform apply
```

#### Step 3: Configure Ansible

1. Navigate to the Ansible directory:
```bash
cd src/ansible
```

2. Update the inventory file:
```bash
cp configs/inventory.example configs/inventory
# Add your server details
```

3. Run the preparation playbook:
```bash
ansible-playbook -i configs/inventory playbooks/prepare-systems.yml
```

#### Step 4: Deploy Kubernetes

1. Run the Kubernetes installation:
```bash
ansible-playbook -i configs/inventory playbooks/install-kubernetes.yml
```

2. Verify the installation:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

#### Step 5: Deploy Add-ons

1. Install monitoring stack:
```bash
kubectl apply -f src/kubernetes/monitoring/
```

2. Install logging stack:
```bash
kubectl apply -f src/kubernetes/logging/
```

### Verification

Run the verification script:
```bash
./scripts/verify-installation.sh
```

## Русский

### Предварительные требования

Перед началом установки убедитесь, что у вас есть:

- **Оборудование**: Bare metal серверы, соответствующие минимальным требованиям
- **Сеть**: Правильная сетевая конфигурация со статическими IP
- **Программное обеспечение**:
  - Terraform >= 1.0
  - Ansible >= 2.9
  - kubectl >= 1.24
  - SSH доступ ко всем серверам

### Шаги установки

#### Шаг 1: Клонирование и настройка

```bash
git clone <repository-url>
cd k8s-lab-baremetal-architecture
```

#### Шаг 2: Настройка инфраструктуры

1. Перейдите в директорию Terraform:
```bash
cd src/terraform
```

2. Скопируйте и измените конфигурацию:
```bash
cp configs/terraform.tfvars.example configs/terraform.tfvars
# Отредактируйте конфигурацию с деталями вашей среды
```

3. Инициализируйте и примените Terraform:
```bash
terraform init
terraform plan
terraform apply
```

#### Шаг 3: Настройка Ansible

1. Перейдите в директорию Ansible:
```bash
cd src/ansible
```

2. Обновите файл инвентаря:
```bash
cp configs/inventory.example configs/inventory
# Добавьте детали ваших серверов
```

3. Запустите плейбук подготовки:
```bash
ansible-playbook -i configs/inventory playbooks/prepare-systems.yml
```

#### Шаг 4: Развертывание Kubernetes

1. Запустите установку Kubernetes:
```bash
ansible-playbook -i configs/inventory playbooks/install-kubernetes.yml
```

2. Проверьте установку:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

#### Шаг 5: Развертывание дополнений

1. Установите стек мониторинга:
```bash
kubectl apply -f src/kubernetes/monitoring/
```

2. Установите стек логирования:
```bash
kubectl apply -f src/kubernetes/logging/
```

### Проверка

Запустите скрипт проверки:
```bash
./scripts/verify-installation.sh
```

### Troubleshooting / Устранение неполадок

#### Common Issues / Частые проблемы

1. **Network connectivity issues**
   - Check firewall rules
   - Verify network configuration
   - Ensure proper DNS resolution

2. **Certificate issues**
   - Regenerate certificates if needed
   - Check certificate expiration
   - Verify certificate paths

3. **Resource constraints**
   - Monitor system resources
   - Scale up if necessary
   - Optimize resource allocation

For more detailed troubleshooting, see [Troubleshooting Guide](troubleshooting.md). 