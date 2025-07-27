#!/bin/bash

# Lab Stands Deployment Script
# Includes example applications for testing

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

# Create namespace for lab stands
create_lab_stands_namespace() {
    log_info "Creating lab-stands namespace..."
    kubectl create namespace lab-stands --dry-run=client -o yaml | kubectl apply -f -
}

# Развертывание Nginx примера
deploy_nginx_example() {
    log_info "Развертывание Nginx примера..."
    
    kubectl apply -f src/kubernetes/lab-stands/nginx-example/nginx-deployment.yaml
    
    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=nginx-example -n lab-stands --timeout=300s
    log_info "Nginx пример развернут успешно"
}

# Развертывание Node.js приложения
deploy_nodejs_app() {
    log_info "Развертывание Node.js приложения..."
    
    kubectl apply -f src/kubernetes/lab-stands/nodejs-app/nodejs-deployment.yaml
    
    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=nodejs-app -n lab-stands --timeout=300s
    log_info "Node.js приложение развернуто успешно"
}

# Развертывание PostgreSQL базы данных
deploy_postgres_db() {
    log_info "Развертывание PostgreSQL базы данных..."
    
    kubectl apply -f src/kubernetes/lab-stands/postgres-db/postgres-deployment.yaml
    
    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=postgres-db -n lab-stands --timeout=300s
    log_info "PostgreSQL база данных развернута успешно"
}

# Создание дополнительных примеров приложений
create_additional_examples() {
    log_info "Создание дополнительных примеров приложений..."
    
    # Python Flask приложение
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
  namespace: lab-stands
  labels:
    app: flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask
        image: python:3.9-alpine
        workingDir: /app
        command: ["python", "app.py"]
        ports:
        - containerPort: 5000
        env:
        - name: FLASK_ENV
          value: "production"
        - name: FLASK_APP
          value: "app.py"
        resources:
          requests:
            memory: 128Mi
            cpu: 100m
          limits:
            memory: 256Mi
            cpu: 500m
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 5000
          initialDelaySeconds: 10
          timeoutSeconds: 3
        volumeMounts:
        - name: app-code
          mountPath: /app
      volumes:
      - name: app-code
        configMap:
          name: flask-app-config
---
apiVersion: v1
kind: Service
metadata:
  name: flask-service
  namespace: lab-stands
  labels:
    app: flask-app
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: 5000
    protocol: TCP
    name: http
  selector:
    app: flask-app
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: flask-app-config
  namespace: lab-stands
data:
  app.py: |
    from flask import Flask, jsonify
    import os
    import time
    
    app = Flask(__name__)
    
    @app.route('/')
    def hello():
        return jsonify({
            'message': 'Hello from Flask!',
            'timestamp': time.time(),
            'hostname': os.uname().nodename
        })
    
    @app.route('/health')
    def health():
        return jsonify({'status': 'healthy'})
    
    @app.route('/ready')
    def ready():
        return jsonify({'status': 'ready'})
    
    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=5000)
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-ingress
  namespace: lab-stands
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: flask-app.k8s-lab.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: flask-service
            port:
              number: 5000
EOF

    # Redis кэш
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  namespace: lab-stands
  labels:
    app: redis-cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-cache
  template:
    metadata:
      labels:
        app: redis-cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: 128Mi
            cpu: 100m
          limits:
            memory: 256Mi
            cpu: 500m
        livenessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 30
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 5
          timeoutSeconds: 3
        volumeMounts:
        - name: redis-data
          mountPath: /data
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: lab-stands
  labels:
    app: redis-cache
spec:
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
    protocol: TCP
    name: redis
  selector:
    app: redis-cache
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: lab-stands
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-storage
EOF

    # Ожидание готовности
    kubectl wait --for=condition=ready pod -l app=flask-app -n lab-stands --timeout=300s
    kubectl wait --for=condition=ready pod -l app=redis-cache -n lab-stands --timeout=300s
    
    log_info "Дополнительные примеры приложений созданы успешно"
}

# Создание тестовых данных
create_test_data() {
    log_info "Создание тестовых данных..."
    
    # Создание ConfigMap с тестовыми данными
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-data
  namespace: lab-stands
data:
  users.json: |
    [
      {"id": 1, "name": "John Doe", "email": "john@example.com"},
      {"id": 2, "name": "Jane Smith", "email": "jane@example.com"},
      {"id": 3, "name": "Bob Johnson", "email": "bob@example.com"}
    ]
  products.json: |
    [
      {"id": 1, "name": "Product A", "price": 100.00},
      {"id": 2, "name": "Product B", "price": 200.00},
      {"id": 3, "name": "Product C", "price": 150.00}
    ]
  config.yaml: |
    database:
      host: postgres-db
      port: 5432
      name: testdb
    redis:
      host: redis-service
      port: 6379
    logging:
      level: info
      format: json
EOF

    log_info "Тестовые данные созданы успешно"
}

# Проверка статуса развертывания
check_deployment_status() {
    log_info "Проверка статуса развертывания..."
    
    echo "=== Статус подов в namespace lab-stands ==="
    kubectl get pods -n lab-stands
    
    echo -e "\n=== Сервисы в namespace lab-stands ==="
    kubectl get services -n lab-stands
    
    echo -e "\n=== Ingress в namespace lab-stands ==="
    kubectl get ingress -n lab-stands
    
    echo -e "\n=== ConfigMaps в namespace lab-stands ==="
    kubectl get configmaps -n lab-stands
}

# Основная функция
main() {
    log_info "Начало развертывания лабораторных стендов..."
    
    check_kubectl
    check_cluster
    create_lab_stands_namespace
    
    # Развертывание примеров приложений
    deploy_nginx_example
    deploy_nodejs_app
    deploy_postgres_db
    create_additional_examples
    create_test_data
    
    # Проверка статуса
    check_deployment_status
    
    log_info "Развертывание лабораторных стендов завершено!"
    log_info "Доступные приложения:"
    log_info "- Nginx: http://nginx-example.k8s-lab.local"
    log_info "- Node.js: http://nodejs-app.k8s-lab.local"
    log_info "- Flask: http://flask-app.k8s-lab.local"
    log_info "- PgAdmin: http://pgadmin.k8s-lab.local (admin@example.com/admin123)"
    log_info "- Redis: redis-service:6379"
}

# Обработка ошибок
trap 'log_error "Произошла ошибка. Выход..."; exit 1' ERR

# Запуск основной функции
main "$@" 