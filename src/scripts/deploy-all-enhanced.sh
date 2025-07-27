#!/bin/bash

# Enhanced Complete Deployment Script for All Components
# Includes basic infrastructure, monitoring, lab stands, and security

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check for required tools
check_prerequisites() {
    log_info "Checking required tools..."
    
    local tools=("kubectl" "helm" "terraform" "ansible")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing tools: ${missing_tools[*]}"
        log_info "Please install missing tools and try again."
        exit 1
    fi
    
    log_info "All required tools found"
}

# Check cluster connectivity
check_cluster() {
    log_info "Checking Kubernetes cluster connectivity..."
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check configuration."
        exit 1
    fi
    
    local cluster_info
    cluster_info=$(kubectl cluster-info | head -n 1)
    log_info "Cluster connection established: $cluster_info"
}

# Create base namespaces
create_namespaces() {
    log_step "Creating base namespaces..."
    
    local namespaces=("monitoring" "lab-stands" "gitops" "jenkins" "storage")
    
    for ns in "${namespaces[@]}"; do
        log_info "Creating namespace: $ns"
        kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
    done
    
    log_info "All namespaces created successfully"
}

# Deploy basic infrastructure
deploy_base_infrastructure() {
    log_step "Развертывание базовой инфраструктуры..."
    
    # Apply basic configurations
    log_info "Применение базовых конфигураций..."
    kubectl apply -f src/kubernetes/namespaces/all-namespaces.yaml
    kubectl apply -f src/kubernetes/storage/storage-classes.yaml
    kubectl apply -f src/kubernetes/network/metallb-config.yaml
    
    # Deploy Ingress Controller
    log_info "Развертывание Ingress Controller..."
    kubectl apply -f src/kubernetes/ingress/nginx-ingress.yaml
    
    # Wait for Ingress Controller readiness
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s
    
    log_info "Базовая инфраструктура развернута успешно"
}

# Deploy monitoring system
deploy_monitoring() {
    log_step "Развертывание системы мониторинга..."
    
    # Run monitoring deployment script
    if [ -f "src/scripts/deploy-monitoring.sh" ]; then
        log_info "Запуск скрипта развертывания мониторинга..."
        ./src/scripts/deploy-monitoring.sh
    else
        log_warn "Скрипт развертывания мониторинга не найден, пропускаем..."
    fi
}

# Deploy lab environments
deploy_lab_stands() {
    log_step "Развертывание лабораторных стендов..."
    
    # Run lab environments deployment script
    if [ -f "src/scripts/deploy-lab-stands.sh" ]; then
        log_info "Запуск скрипта развертывания лабораторных стендов..."
        ./src/scripts/deploy-lab-stands.sh
    else
        log_warn "Скрипт развертывания лабораторных стендов не найден, пропускаем..."
    fi
}

# Deploy security components
deploy_security() {
    log_step "Развертывание компонентов безопасности..."
    
    # Run security deployment script
    if [ -f "src/scripts/deploy-security.sh" ]; then
        log_info "Запуск скрипта развертывания безопасности..."
        ./src/scripts/deploy-security.sh
    else
        log_warn "Скрипт развертывания безопасности не найден, пропускаем..."
    fi
}

# Deploy GitOps components
deploy_gitops() {
    log_step "Развертывание GitOps компонентов..."
    
    # Deploy ArgoCD
    log_info "Развертывание ArgoCD..."
    kubectl apply -f src/kubernetes/gitops/argocd/argocd-install.yaml
    
    # Wait for ArgoCD readiness
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    
    # Deploy Flux (optional)
    if [ -f "src/kubernetes/gitops/flux/flux-install.yaml" ]; then
        log_info "Развертывание Flux..."
        kubectl apply -f src/kubernetes/gitops/flux/flux-install.yaml
    fi
    
    log_info "GitOps компоненты развернуты успешно"
}

# Deploy CI/CD components
deploy_cicd() {
    log_step "Развертывание CI/CD компонентов..."
    
    # Deploy Jenkins
    log_info "Развертывание Jenkins..."
    kubectl apply -f src/kubernetes/jenkins/jenkins-deployment.yaml
    
    # Wait for Jenkins readiness
    kubectl wait --for=condition=ready pod -l app=jenkins -n jenkins --timeout=300s
    
    # Deploy Tekton (optional)
    if [ -f "src/kubernetes/tekton/tekton-install.yaml" ]; then
        log_info "Развертывание Tekton..."
        kubectl apply -f src/kubernetes/tekton/tekton-install.yaml
    fi
    
    log_info "CI/CD компоненты развернуты успешно"
}

# Check deployment status
check_deployment_status() {
    log_step "Проверка статуса развертывания..."
    
    echo -e "\n=== Статус всех namespace'ов ==="
    kubectl get namespaces
    
    echo -e "\n=== Статус подов по namespace'ам ==="
    local namespaces=("monitoring" "lab-stands" "gitops" "jenkins" "argocd" "ingress-nginx")
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &> /dev/null; then
            echo "--- $ns ---"
            kubectl get pods -n "$ns" --no-headers | head -5
        fi
    done
    
    echo -e "\n=== Сервисы ==="
    kubectl get services --all-namespaces | head -10
    
    echo -e "\n=== Ingress ==="
    kubectl get ingress --all-namespaces
}

# Create deployment report
create_deployment_report() {
    log_step "Создание отчета о развертывании..."
    
    local report_file
    report_file="deployment-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Отчет о развертывании k8s-lab-baremetal-architecture"
        echo "Дата: $(date)"
        echo "=================================================="
        echo ""
        echo "Статус развертывания:"
        kubectl get pods --all-namespaces --field-selector=status.phase!=Running
        echo ""
        echo "Доступные сервисы:"
        echo "- Prometheus: http://prometheus.k8s-lab.local"
        echo "- Grafana: http://grafana.k8s-lab.local (admin/admin123)"
        echo "- Alertmanager: http://alertmanager.k8s-lab.local"
        echo "- Kibana: http://kibana.k8s-lab.local"
        echo "- Jenkins: http://jenkins.k8s-lab.local"
        echo "- ArgoCD: http://argocd.k8s-lab.local"
        echo "- Nginx Example: http://nginx-example.k8s-lab.local"
        echo "- Node.js App: http://nodejs-app.k8s-lab.local"
        echo "- Flask App: http://flask-app.k8s-lab.local"
        echo "- PgAdmin: http://pgadmin.k8s-lab.local (admin@example.com/admin123)"
        echo ""
        echo "Команды для проверки:"
        echo "- kubectl get pods --all-namespaces"
        echo "- kubectl get services --all-namespaces"
        echo "- kubectl get ingress --all-namespaces"
        echo "- kubectl get networkpolicies --all-namespaces"
    } > "$report_file"
    
    log_info "Отчет сохранен в файл: $report_file"
}

# Error cleanup function
cleanup_on_error() {
    log_error "Произошла ошибка во время развертывания"
    log_info "Выполняется очистка..."
    
    # Here you can add cleanup logic if needed
    log_warn "Для полной очистки выполните: kubectl delete namespace monitoring lab-stands gitops jenkins argocd"
}

# Main function
main() {
    local start_time
    start_time=$(date +%s)
    
    log_info "Начало полного развертывания k8s-lab-baremetal-architecture..."
    log_info "Время начала: $(date)"
    
    # Checks
    check_prerequisites
    check_cluster
    
    # Deploy components
    create_namespaces
    deploy_base_infrastructure
    deploy_monitoring
    deploy_lab_stands
    deploy_security
    deploy_gitops
    deploy_cicd
    
    # Check and report
    check_deployment_status
    create_deployment_report
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "Развертывание завершено успешно!"
    log_info "Общее время развертывания: ${duration} секунд"
    log_info "Время завершения: $(date)"
    
    echo -e "\n${GREEN}🎉 Развертывание завершено успешно! 🎉${NC}"
    echo -e "${BLUE}Проверьте отчет для получения дополнительной информации.${NC}"
}

# Error handling
trap 'cleanup_on_error; exit 1' ERR

# Interrupt handling
trap 'log_warn "Получен сигнал прерывания. Завершение..."; exit 1' INT TERM

# Run main function
main "$@" 