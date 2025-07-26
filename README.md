# Kubernetes Baremetal Lab Architecture

[English](#english) | [Русский](#russian)

## English

This project provides a complete solution for deploying and managing Kubernetes clusters on bare metal infrastructure. It includes automation tools, configuration management, and comprehensive documentation for building production-ready Kubernetes environments.

### Features

- **Infrastructure as Code**: Terraform configurations for bare metal infrastructure provisioning
- **Configuration Management**: Ansible playbooks for system configuration and Kubernetes installation
- **Kubernetes Deployment**: Automated Kubernetes cluster deployment with best practices
- **CI/CD Pipeline**: Jenkins deployment with persistent storage and node affinity
- **GitOps Management**: ArgoCD for GitOps workflow and application management
- **Monitoring & Logging**: Prometheus, Grafana, and ELK stack integration
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
5. Check [Examples](examples/) for common use cases

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

## Русский

Этот проект предоставляет полное решение для развертывания и управления кластерами Kubernetes на bare metal инфраструктуре. Включает инструменты автоматизации, управление конфигурациями и подробную документацию для создания готовых к продакшену сред Kubernetes.

### Возможности

- **Infrastructure as Code**: Конфигурации Terraform для подготовки bare metal инфраструктуры
- **Управление конфигурациями**: Ansible плейбуки для настройки системы и установки Kubernetes
- **Развертывание Kubernetes**: Автоматизированное развертывание кластера Kubernetes с лучшими практиками
- **CI/CD Pipeline**: Развертывание Jenkins с постоянным хранилищем и привязкой к узлам
- **GitOps управление**: ArgoCD для GitOps workflow и управления приложениями
- **Мониторинг и логирование**: Интеграция Prometheus, Grafana и ELK стека
- **Управление артефактами**: JFrog Artifactory для хранения и управления артефактами
- **Сетевое управление**: MetalLB для симуляции балансировщика нагрузки и Ingress контроллеров
- **Управление хранилищем**: Множественные классы хранилищ с привязкой к узлам
- **Лабораторные приложения**: Примеры приложений для тестирования и разработки
- **Безопасность**: Усиленные конфигурации и лучшие практики безопасности
- **Документация**: Подробные руководства и примеры

### Быстрый старт

1. Клонируйте репозиторий
2. Изучите [Обзор архитектуры](docs/architecture.md)
3. Следуйте [Руководству по установке](docs/installation.md)
4. Разверните все компоненты:
   - **YAML подход**: `./src/scripts/deploy-all.sh`
   - **Helm подход**: `./src/scripts/deploy-helm.sh`
5. Посмотрите [Примеры](examples/) для типичных случаев использования

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
│   └── scripts/    # Утилитарные скрипты
├── configs/        # Файлы конфигураций
└── examples/       # Примеры развертываний
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 