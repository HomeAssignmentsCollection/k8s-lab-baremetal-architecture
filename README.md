# Kubernetes Baremetal Lab Architecture

[English](#english) | [Русский](#russian)

## English

This project provides a complete solution for deploying and managing Kubernetes clusters on bare metal infrastructure. It includes automation tools, configuration management, comprehensive monitoring, and troubleshooting capabilities for building production-ready Kubernetes environments.

### Features

- **Infrastructure as Code**: Terraform configurations for bare metal infrastructure provisioning
- **Configuration Management**: Ansible playbooks for system configuration and Kubernetes installation
- **Kubernetes Deployment**: Automated Kubernetes cluster deployment with best practices
- **CI/CD Pipeline**: Jenkins deployment with persistent storage and node affinity
- **GitOps Management**: ArgoCD for GitOps workflow and application management
- **Monitoring & Logging**: Prometheus, Grafana, and ELK stack integration
- **Logging & Troubleshooting**: Comprehensive health checks, backup tools, and diagnostic methodologies
- **Artifact Management**: JFrog Artifactory for artifact storage and management
- **Network Management**: MetalLB for load balancer simulation and Ingress controllers
- **Storage Management**: Multiple storage classes with node affinity
- **Lab Applications**: Example applications for testing and development
- **Security**: Hardened configurations and security best practices
- **Code Quality**: Comprehensive linting, testing, and validation tools
- **Documentation**: Comprehensive guides and examples

### Quick Start

1. Clone the repository
2. Review the [Architecture Overview](docs/architecture.md)
3. Follow the [Installation Guide](docs/installation.md)
4. Deploy all components: 
   - **YAML approach**: `./src/scripts/deploy-all.sh`
   - **Helm approach**: `./src/scripts/deploy-helm.sh`
5. Monitor cluster health: `./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh`
6. Check [Examples](examples/) for common use cases

### Project Structure

```
├── docs/           # Documentation
├── src/            # Source code
│   ├── ansible/    # Ansible playbooks
│   ├── terraform/  # Terraform configurations
│   ├── kubernetes/ # Kubernetes manifests (YAML)
│   ├── helm/       # Helm charts (optional)
│   │   ├── jenkins/        # CI/CD components
│   │   ├── gitops/         # GitOps (ArgoCD)
│   │   ├── monitoring/     # Monitoring stack
│   │   ├── artifacts/      # Artifact management
│   │   ├── network/        # Network components
│   │   ├── storage/        # Storage classes
│   │   ├── lab-stands/     # Lab applications
│   │   └── namespaces/     # Namespace definitions
│   ├── logging-and-troubleshooting/ # Health checks and diagnostics
│   │   ├── methodology/    # Troubleshooting and logging methodologies
│   │   ├── health-checks/  # Hardware, config, and K8s health checks
│   │   ├── backup/         # etcd backup and restore tools
│   │   ├── scripts/        # Main troubleshooting toolbox
│   │   ├── README.md       # Comprehensive documentation
│   │   └── QUICK_START.md  # Quick start guide
│   └── scripts/    # Utility scripts
├── configs/        # Configuration files
├── code-quality/   # Code quality tools and linting
│   ├── linters/           # Linting tools for different file types
│   ├── pre-commit-hooks/  # Git pre-commit hooks
│   ├── test-tools/        # Testing and validation tools
│   ├── configs/           # Configuration files for linting tools
│   └── documentation/     # Documentation for code quality tools
└── examples/       # Example deployments
```

### Monitoring and Troubleshooting

The project includes a comprehensive logging and troubleshooting module that provides:

- **Health Checks**: Automated hardware, configuration, and Kubernetes component health monitoring
- **Backup Tools**: etcd backup and restore procedures with verification
- **Diagnostic Methodologies**: Systematic approaches to troubleshooting cluster issues
- **Log Collection**: Automated log gathering and analysis tools
- **Reporting**: Comprehensive health reports and recommendations

**Quick Health Check:**
```bash
# Run complete health check
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh

# Run individual checks
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh hardware
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh config
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh kubernetes

# Create backup and generate report
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh backup
./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh report
```

## Русский

Этот проект предоставляет полное решение для развертывания и управления кластерами Kubernetes на bare metal инфраструктуре. Включает инструменты автоматизации, управление конфигурациями, комплексный мониторинг и возможности диагностики для создания готовых к продакшену сред Kubernetes.

### Возможности

- **Infrastructure as Code**: Конфигурации Terraform для подготовки bare metal инфраструктуры
- **Управление конфигурациями**: Ansible плейбуки для настройки системы и установки Kubernetes
- **Развертывание Kubernetes**: Автоматизированное развертывание кластера Kubernetes с лучшими практиками
- **CI/CD Pipeline**: Развертывание Jenkins с постоянным хранилищем и привязкой к узлам
- **GitOps управление**: ArgoCD для GitOps workflow и управления приложениями
- **Мониторинг и логирование**: Интеграция Prometheus, Grafana и ELK стека
- **Логирование и диагностика**: Комплексные проверки здоровья, инструменты бэкапа и диагностические методологии
- **Управление артефактами**: JFrog Artifactory для хранения и управления артефактами
- **Сетевое управление**: MetalLB для симуляции балансировщика нагрузки и Ingress контроллеров
- **Управление хранилищем**: Множественные классы хранилищ с привязкой к узлам
- **Лабораторные приложения**: Примеры приложений для тестирования и разработки
- **Безопасность**: Усиленные конфигурации и лучшие практики безопасности
- **Качество кода**: Комплексные инструменты линтинга, тестирования и валидации
- **Документация**: Подробные руководства и примеры

### Быстрый старт

1. Клонируйте репозиторий
2. Изучите [Обзор архитектуры](docs/architecture.md)
3. Следуйте [Руководству по установке](docs/installation.md)
4. Разверните все компоненты:
   - **YAML подход**: `./src/scripts/deploy-all.sh`
   - **Helm подход**: `./src/scripts/deploy-helm.sh`
5. Проверьте здоровье кластера: `./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh`
6. Посмотрите [Примеры](examples/) для типичных случаев использования

### Структура проекта

```
├── docs/           # Документация
├── src/            # Исходный код
│   ├── ansible/    # Ansible плейбуки
│   ├── terraform/  # Конфигурации Terraform
│   ├── kubernetes/ # Манифесты Kubernetes (YAML)
│   ├── helm/       # Helm чарты (опционально)
│   │   ├── jenkins/        # CI/CD компоненты
│   │   ├── gitops/         # GitOps (ArgoCD)
│   │   ├── monitoring/     # Стек мониторинга
│   │   ├── artifacts/      # Управление артефактами
│   │   ├── network/        # Сетевые компоненты
│   │   ├── storage/        # Классы хранилищ
│   │   ├── lab-stands/     # Лабораторные приложения
│   │   └── namespaces/     # Определения namespace
│   ├── logging-and-troubleshooting/ # Проверки здоровья и диагностика
│   │   ├── methodology/    # Методологии диагностики и логирования
│   │   ├── health-checks/  # Проверки железа, конфигурации и K8s
│   │   ├── backup/         # Инструменты бэкапа и восстановления etcd
│   │   ├── scripts/        # Главный toolbox диагностики
│   │   ├── README.md       # Подробная документация
│   │   └── QUICK_START.md  # Руководство быстрого старта
│   └── scripts/    # Утилитарные скрипты
├── configs/        # Файлы конфигураций
├── code-quality/   # Инструменты качества кода и линтинга
│   ├── linters/           # Инструменты линтинга для разных типов файлов
│   ├── pre-commit-hooks/  # Git pre-commit хуки
│   ├── test-tools/        # Инструменты тестирования и валидации
│   ├── configs/           # Конфигурационные файлы для инструментов линтинга
│   └── documentation/     # Документация для инструментов качества кода
└── examples/       # Примеры развертываний
```

### Мониторинг и диагностика

Проект включает комплексный модуль логирования и диагностики, который предоставляет:

- **Проверки здоровья**: Автоматизированный мониторинг железа, конфигурации и компонентов Kubernetes
- **Инструменты бэкапа**: Процедуры бэкапа и восстановления etcd с верификацией
- **Диагностические методологии**: Систематические подходы к диагностике проблем кластера
- **Сбор логов**: Автоматизированные инструменты сбора и анализа логов
- **Отчетность**: Комплексные отчеты о здоровье и рекомендации

**Быстрая проверка здоровья:**
```bash
# Запустить полную проверку здоровья
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh

# Запустить отдельные проверки
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh hardware
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh config
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh kubernetes

# Создать бэкап и сгенерировать отчет
sudo ./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh backup
./src/logging-and-troubleshooting/scripts/cluster-troubleshooting-toolbox.sh report
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 