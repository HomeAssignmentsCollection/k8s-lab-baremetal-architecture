# Terraform variables for Kubernetes Baremetal Lab
# Переменные Terraform для Kubernetes Baremetal Lab

# Infrastructure variables
# Переменные инфраструктуры
variable "control_plane_ips" {
  description = "List of control plane node IP addresses"
  type        = list(string)
  default     = ["192.168.1.10", "192.168.1.11", "192.168.1.12"]
}

variable "worker_ips" {
  description = "List of worker node IP addresses"
  type        = list(string)
  default     = ["192.168.1.20", "192.168.1.21", "192.168.1.22"]
}

variable "load_balancer_ip" {
  description = "Load balancer IP address"
  type        = string
  default     = "192.168.1.100"
}

variable "network_gateway" {
  description = "Network gateway IP address"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS server IP addresses"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# SSH configuration
# Конфигурация SSH
variable "ssh_user" {
  description = "SSH username for node access"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_port" {
  description = "SSH port for node access"
  type        = number
  default     = 22
}

# Infrastructure configuration
# Конфигурация инфраструктуры
variable "control_plane_nodes" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
}

variable "worker_nodes" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "node_prefix" {
  description = "Prefix for node names"
  type        = string
  default     = "k8s"
}

variable "network_cidr" {
  description = "Network CIDR for the cluster"
  type        = string
  default     = "10.0.0.0/16"
}

# Kubernetes configuration
# Конфигурация Kubernetes
variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.28.0"
}

variable "container_runtime" {
  description = "Container runtime to use (containerd, docker)"
  type        = string
  default     = "containerd"
}

variable "cni_plugin" {
  description = "CNI plugin to use (flannel, calico, weave)"
  type        = string
  default     = "flannel"
}

variable "pod_cidr" {
  description = "Pod CIDR for Kubernetes"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes"
  type        = string
  default     = "10.96.0.0/12"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "baremetal-cluster"
}

variable "cluster_domain" {
  description = "Kubernetes cluster domain"
  type        = string
  default     = "cluster.local"
}

# Security configuration
# Конфигурация безопасности
variable "enable_rbac" {
  description = "Enable RBAC for Kubernetes"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable network policies"
  type        = bool
  default     = true
}

variable "enable_pod_security_policies" {
  description = "Enable pod security policies"
  type        = bool
  default     = false
}

# Monitoring and logging
# Мониторинг и логирование
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack (ELK/Fluentd)"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable ingress controller"
  type        = bool
  default     = true
}

# Storage configuration
# Конфигурация хранилища
variable "enable_local_storage" {
  description = "Enable local storage provisioner"
  type        = bool
  default     = true
}

variable "enable_nfs_storage" {
  description = "Enable NFS storage provisioner"
  type        = bool
  default     = false
}

variable "nfs_server" {
  description = "NFS server IP address"
  type        = string
  default     = ""
}

variable "nfs_path" {
  description = "NFS export path"
  type        = string
  default     = "/exports"
}

# Backup configuration
# Конфигурация резервного копирования
variable "enable_backup" {
  description = "Enable backup solution"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# Tags and labels
# Теги и метки
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "k8s-baremetal-lab"
}

variable "owner" {
  description = "Project owner"
  type        = string
  default     = "admin"
} 