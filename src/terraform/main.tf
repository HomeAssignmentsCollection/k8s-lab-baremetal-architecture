# Main Terraform configuration for Kubernetes Baremetal Lab
# Main Terraform configuration for Kubernetes Baremetal Lab

terraform {
  required_version = ">= 1.0"
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Infrastructure configuration variables are defined in variables.tf
# Infrastructure configuration variables are defined in variables.tf

# Data sources for existing infrastructure
# Data sources for existing infrastructure
# data "external" "get_nodes" {
#   program = ["bash", "${path.module}/scripts/get-nodes.sh"]
# }

# Local values for computed configurations
# Local values for computed configurations
locals {
  # Generate node configurations
  # Generate node configurations
  control_plane_ips = var.control_plane_ips
  worker_ips        = var.worker_ips
  load_balancer_ip  = var.load_balancer_ip

  # Kubernetes configuration
  # Kubernetes configuration
  kubernetes_config = {
    version      = var.kubernetes_version
    pod_cidr     = var.pod_cidr
    service_cidr = var.service_cidr
    network_cidr = var.network_cidr
  }

  # Network configuration
  # Network configuration
  network_config = {
    cidr        = var.network_cidr
    gateway     = var.network_gateway
    dns_servers = var.dns_servers
  }
}

# Output values for other modules
# Output values for other modules
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
# Generate inventory file for Ansible
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
# Generate Kubernetes configuration
resource "local_file" "kubernetes_config" {
  content = templatefile("${path.module}/templates/kubeadm-config.tpl", {
    kubernetes_version = var.kubernetes_version,
    pod_cidr           = var.pod_cidr,
    service_cidr       = var.service_cidr,
    load_balancer_ip   = local.load_balancer_ip
  })
  filename = "${path.module}/../kubernetes/config/kubeadm-config.yaml"
} 