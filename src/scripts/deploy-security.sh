#!/bin/bash

# Security Components Deployment Script
# Includes Network Policies, Pod Security Policies, RBAC

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl and try again."
        exit 1
    fi
}

# Check cluster connectivity
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check configuration."
        exit 1
    fi
    log_info "Cluster connection established"
}

# Deploy Network Policies
deploy_network_policies() {
    log_info "Deploying Network Policies..."
    
    kubectl apply -f src/kubernetes/security/network-policies/network-policies.yaml
    
    log_info "Network Policies deployed successfully"
}

# Deploy Pod Security Policies
deploy_pod_security_policies() {
    log_info "Deploying Pod Security Policies..."
    
    kubectl apply -f src/kubernetes/security/pod-security/pod-security-policies.yaml
    
    log_info "Pod Security Policies deployed successfully"
}

# Create additional RBAC rules
create_additional_rbac() {
    log_info "Creating additional RBAC rules..."
    
    # Create ClusterRole for monitoring
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "nodes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: monitoring-role
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
- kind: ServiceAccount
  name: grafana
  namespace: monitoring
EOF

    # Create Role for lab environments
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: lab-stands-role
  namespace: lab-stands
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: lab-stands-role-binding
  namespace: lab-stands
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: lab-stands-role
subjects:
- kind: ServiceAccount
  name: default
  namespace: lab-stands
EOF

    log_info "Дополнительные RBAC правила созданы успешно"
}

# Create Security Context for pods
create_security_contexts() {
    log_info "Создание Security Context для подов..."
    
    # Update deployments with security context
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-example-secure
  namespace: lab-stands
  labels:
    app: nginx-example-secure
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-example-secure
  template:
    metadata:
      labels:
        app: nginx-example-secure
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            memory: 64Mi
            cpu: 50m
          limits:
            memory: 128Mi
            cpu: 200m
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
          readOnly: true
        - name: nginx-temp
          mountPath: /tmp
        - name: nginx-cache
          mountPath: /var/cache/nginx
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
      - name: nginx-temp
        emptyDir: {}
      - name: nginx-cache
        emptyDir: {}
EOF

    log_info "Security Context созданы успешно"
}

# Create Resource Quotas
create_resource_quotas() {
    log_info "Создание Resource Quotas..."
    
    # Resource Quota for lab-stands
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: lab-stands-quota
  namespace: lab-stands
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 4Gi
    limits.cpu: "8"
    limits.memory: 8Gi
    pods: "20"
    services: "10"
    persistentvolumeclaims: "10"
EOF

    # Resource Quota for monitoring
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: monitoring-quota
  namespace: monitoring
spec:
  hard:
    requests.cpu: "6"
    requests.memory: 6Gi
    limits.cpu: "12"
    limits.memory: 12Gi
    pods: "30"
    services: "15"
    persistentvolumeclaims: "20"
EOF

    log_info "Resource Quotas созданы успешно"
}

# Create Limit Ranges
create_limit_ranges() {
    log_info "Создание Limit Ranges..."
    
    # Limit Range for lab-stands
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: lab-stands-limits
  namespace: lab-stands
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
  - default:
      cpu: 1000m
      memory: 1Gi
    defaultRequest:
      cpu: 200m
      memory: 256Mi
    type: Pod
EOF

    # Limit Range for monitoring
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: monitoring-limits
  namespace: monitoring
spec:
  limits:
  - default:
      cpu: 1000m
      memory: 1Gi
    defaultRequest:
      cpu: 200m
      memory: 256Mi
    type: Container
  - default:
      cpu: 2000m
      memory: 2Gi
    defaultRequest:
      cpu: 400m
      memory: 512Mi
    type: Pod
EOF

    log_info "Limit Ranges созданы успешно"
}

# Check deployment status
check_deployment_status() {
    log_info "Проверка статуса развертывания безопасности..."
    
    echo "=== Network Policies ==="
    kubectl get networkpolicies --all-namespaces
    
    echo -e "\n=== Pod Security Policies ==="
    kubectl get podsecuritypolicies
    
    echo -e "\n=== Resource Quotas ==="
    kubectl get resourcequotas --all-namespaces
    
    echo -e "\n=== Limit Ranges ==="
    kubectl get limitranges --all-namespaces
}

# Main function
main() {
    log_info "Начало развертывания компонентов безопасности..."
    
    check_kubectl
    check_cluster
    
    # Deploy security components
    deploy_network_policies
    deploy_pod_security_policies
    create_additional_rbac
    create_security_contexts
    create_resource_quotas
    create_limit_ranges
    
    # Check status
    check_deployment_status
    
    log_info "Развертывание компонентов безопасности завершено!"
    log_info "Применены следующие меры безопасности:"
    log_info "- Network Policies для изоляции трафика"
    log_info "- Pod Security Policies для ограничения привилегий"
    log_info "- RBAC для контроля доступа"
    log_info "- Security Context для подов"
    log_info "- Resource Quotas для ограничения ресурсов"
    log_info "- Limit Ranges для установки лимитов"
}

# Error handling
trap 'log_error "Произошла ошибка. Выход..."; exit 1' ERR

# Run main function
main "$@" 