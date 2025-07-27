# Terraform variables for Kubernetes Baremetal Lab
# Переменные Terraform для Kubernetes Baremetal Lab

# Network configuration
# Сетевая конфигурация
variable "network_cidr" {
  description = "Network CIDR block"
  type        = string
  default     = "192.168.1.0/24"
}

variable "network_gateway" {
  description = "Network gateway IP"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# Node IPs
# IP адреса узлов
variable "control_plane_ips" {
  description = "Control plane node IPs"
  type        = list(string)
  default     = ["192.168.1.10", "192.168.1.11", "192.168.1.12"]
}

variable "worker_ips" {
  description = "Worker node IPs"
  type        = list(string)
  default     = ["192.168.1.20", "192.168.1.21", "192.168.1.22"]
}

variable "load_balancer_ip" {
  description = "Load balancer IP"
  type        = string
  default     = "192.168.1.100"
}

# Kubernetes configuration
# Конфигурация Kubernetes
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.0"
}

variable "pod_cidr" {
  description = "Pod CIDR block"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Service CIDR block"
  type        = string
  default     = "10.96.0.0/12"
}

# Node configuration
# Конфигурация узлов
variable "node_prefix" {
  description = "Node name prefix"
  type        = string
  default     = "k8s-node"
} 