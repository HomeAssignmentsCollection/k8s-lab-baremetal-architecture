#!/bin/bash

# Скрипт для развертывания системы мониторинга
# Включает Prometheus, Grafana, Alertmanager, ELK Stack

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для логирования
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия kubectl
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl не найден. Установите kubectl и попробуйте снова."
        exit 1
    fi
}

# Проверка подключения к кластеру
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Не удается подключиться к кластеру Kubernetes. Проверьте конфигурацию."
        exit 1
    fi
    log_info "Подключение к кластеру установлено"
}

# Создание namespace для мониторинга
create_monitoring_namespace() {
    log_info "Создание namespace monitoring..."
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
}

# Развертывание Prometheus
deploy_prometheus() {
    log_info "Развертывание Prometheus..."
    
    # Применение RBAC
    kubectl apply -f src/kubernetes/monitoring/prometheus/prometheus-deployment.yaml
    
    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s
    log_info "Prometheus развернут успешно"
}

# Развертывание Grafana
deploy_grafana() {
    log_info "Развертывание Grafana..."
    
    kubectl apply -f src/kubernetes/monitoring/grafana/grafana-deployment.yaml
    
    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
    log_info "Grafana развернут успешно"
}

# Развертывание Alertmanager
deploy_alertmanager() {
    log_info "Развертывание Alertmanager..."
    
    kubectl apply -f src/kubernetes/monitoring/alertmanager/alertmanager-deployment.yaml
    
    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=alertmanager -n monitoring --timeout=300s
    log_info "Alertmanager развернут успешно"
}

# Развертывание Elasticsearch
deploy_elasticsearch() {
    log_info "Развертывание Elasticsearch..."
    
    kubectl apply -f src/kubernetes/monitoring/elk/elasticsearch-deployment.yaml
    
    # Ожидание готовности всех подов
    kubectl wait --for=condition=ready pod -l app=elasticsearch -n monitoring --timeout=600s
    log_info "Elasticsearch развернут успешно"
}

# Развертывание Kibana
deploy_kibana() {
    log_info "Развертывание Kibana..."
    
    kubectl apply -f src/kubernetes/monitoring/elk/kibana-deployment.yaml
    
    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=kibana -n monitoring --timeout=300s
    log_info "Kibana развернут успешно"
}

# Развертывание Node Exporter
deploy_node_exporter() {
    log_info "Развертывание Node Exporter..."
    
    # Создание DaemonSet для Node Exporter
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.6.0
        ports:
        - containerPort: 9100
        resources:
          requests:
            memory: 64Mi
            cpu: 50m
          limits:
            memory: 128Mi
            cpu: 200m
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: root
          mountPath: /rootfs
          readOnly: true
        args:
        - --path.procfs=/host/proc
        - --path.sysfs=/host/sys
        - --path.rootfs=/rootfs
        - --web.listen-address=:9100
        - --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: root
        hostPath:
          path: /
      hostNetwork: true
      hostPID: true
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
EOF

    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=node-exporter -n monitoring --timeout=300s
    log_info "Node Exporter развернут успешно"
}

# Развертывание Kube State Metrics
deploy_kube_state_metrics() {
    log_info "Развертывание Kube State Metrics..."
    
    # Создание Kube State Metrics
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    app: kube-state-metrics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-state-metrics
  template:
    metadata:
      labels:
        app: kube-state-metrics
    spec:
      serviceAccountName: kube-state-metrics
      containers:
      - name: kube-state-metrics
        image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.8.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: 128Mi
            cpu: 100m
          limits:
            memory: 256Mi
            cpu: 500m
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          timeoutSeconds: 30
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          timeoutSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    app: kube-state-metrics
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: kube-state-metrics
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-state-metrics
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets", "nodes", "pods", "services", "resourcequotas", "replicationcontrollers", "limitranges", "persistentvolumeclaims", "persistentvolumes", "namespaces", "endpoints"]
  verbs: ["list", "watch"]
- apiGroups: ["apps"]
  resources: ["statefulsets", "daemonsets", "deployments", "replicasets"]
  verbs: ["list", "watch"]
- apiGroups: ["batch"]
  resources: ["cronjobs", "jobs"]
  verbs: ["list", "watch"]
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["list", "watch"]
- apiGroups: ["authentication.k8s.io"]
  resources: ["tokenreviews"]
  verbs: ["create"]
- apiGroups: ["authorization.k8s.io"]
  resources: ["subjectaccessreviews"]
  verbs: ["create"]
- apiGroups: ["policy"]
  resources: ["poddisruptionbudgets"]
  verbs: ["list", "watch"]
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests"]
  verbs: ["list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses", "volumeattachments"]
  verbs: ["list", "watch"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  verbs: ["list", "watch"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
  verbs: ["list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies", "ingresses", "ingressclasses"]
  verbs: ["list", "watch"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["list", "watch"]
- apiGroups: ["scheduling.k8s.io"]
  resources: ["priorityclasses"]
  verbs: ["list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-state-metrics
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-state-metrics
subjects:
- kind: ServiceAccount
  name: kube-state-metrics
  namespace: monitoring
EOF

    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=kube-state-metrics -n monitoring --timeout=300s
    log_info "Kube State Metrics развернут успешно"
}

# Проверка статуса развертывания
check_deployment_status() {
    log_info "Проверка статуса развертывания..."
    
    echo "=== Статус подов в namespace monitoring ==="
    kubectl get pods -n monitoring
    
    echo -e "\n=== Сервисы в namespace monitoring ==="
    kubectl get services -n monitoring
    
    echo -e "\n=== Ingress в namespace monitoring ==="
    kubectl get ingress -n monitoring
}

# Основная функция
main() {
    log_info "Начало развертывания системы мониторинга..."
    
    check_kubectl
    check_cluster
    create_monitoring_namespace
    
    # Развертывание компонентов мониторинга
    deploy_prometheus
    deploy_grafana
    deploy_alertmanager
    deploy_elasticsearch
    deploy_kibana
    deploy_node_exporter
    deploy_kube_state_metrics
    
    # Проверка статуса
    check_deployment_status
    
    log_info "Развертывание системы мониторинга завершено!"
    log_info "Доступные сервисы:"
    log_info "- Prometheus: http://prometheus.k8s-lab.local"
    log_info "- Grafana: http://grafana.k8s-lab.local (admin/admin123)"
    log_info "- Alertmanager: http://alertmanager.k8s-lab.local"
    log_info "- Kibana: http://kibana.k8s-lab.local"
}

# Обработка ошибок
trap 'log_error "Произошла ошибка. Выход..."; exit 1' ERR

# Запуск основной функции
main "$@" 