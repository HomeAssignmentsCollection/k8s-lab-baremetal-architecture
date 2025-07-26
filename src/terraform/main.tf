# Main Terraform configuration for Kubernetes Baremetal Lab
# Основная конфигурация Terraform для Kubernetes Baremetal Lab

terraform {
  required_version = ">= 1.0"
  required_providers {
    # Add your cloud provider here if using cloud resources
    # Добавьте ваш облачный провайдер здесь, если используете облачные ресурсы
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> 4.0"
    # }
  }
}

# Infrastructure configuration variables are defined in variables.tf
# Переменные конфигурации инфраструктуры определены в variables.tf

# Data sources for existing infrastructure
# Источники данных для существующей инфраструктуры
data "external" "get_nodes" {
  program = ["bash", "${path.module}/scripts/get-nodes.sh"]
}

# Local values for computed configurations
# Локальные значения для вычисленных конфигураций
locals {
  # Generate node configurations
  # Генерация конфигураций узлов
  control_plane_ips = var.control_plane_ips
  worker_ips        = var.worker_ips
  load_balancer_ip  = var.load_balancer_ip
  
  # Kubernetes configuration
  # Конфигурация Kubernetes
  kubernetes_config = {
    version     = var.kubernetes_version
    pod_cidr    = var.pod_cidr
    service_cidr = var.service_cidr
    network_cidr = var.network_cidr
  }
  
  # Network configuration
  # Сетевая конфигурация
  network_config = {
    cidr = var.network_cidr
    gateway = var.network_gateway
    dns_servers = var.dns_servers
  }
}

# Output values for other modules
# Выходные значения для других модулей
output "kubernetes_config" {
  description = "Kubernetes cluster configuration"
  value       = local.kubernetes_config
}

output "network_config" {
  description = "Network configuration"
  value       = local.network_config
}

output "control_plane_ips" {
  description = "Control plane node IPs"
  value       = local.control_plane_ips
}

output "worker_ips" {
  description = "Worker node IPs"
  value       = local.worker_ips
}

output "load_balancer_ip" {
  description = "Load balancer IP"
  value       = local.load_balancer_ip
}

# Generate inventory file for Ansible
# Генерация файла инвентаря для Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    control_plane_ips = local.control_plane_ips,
    worker_ips        = local.worker_ips,
    load_balancer_ip  = local.load_balancer_ip,
    node_prefix       = var.node_prefix
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}

# Generate Kubernetes configuration
# Генерация конфигурации Kubernetes
resource "local_file" "kubernetes_config" {
  content = templatefile("${path.module}/templates/kubeadm-config.tpl", {
    kubernetes_version = var.kubernetes_version,
    pod_cidr          = var.pod_cidr,
    service_cidr      = var.service_cidr,
    load_balancer_ip  = local.load_balancer_ip
  })
  filename = "${path.module}/../kubernetes/config/kubeadm-config.yaml"
} 