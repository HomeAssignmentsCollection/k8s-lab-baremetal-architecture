# Project Structure / Структура проекта

[English](#english) | [Русский](#russian)

## English

### Complete Project Structure

```
k8s-lab-baremetal-architecture/
├── docs/                           # Documentation
│   ├── architecture.md             # System architecture overview
│   ├── installation.md             # Installation guide
│   ├── requirements.md             # System requirements
│   ├── troubleshooting.md          # Troubleshooting guide
│   ├── installation-guides/        # Detailed installation guides
│   │   └── step-by-step-installation.md  # Step-by-step installation
│   ├── diagrams/                   # Architecture diagrams
│   │   └── architecture-overview.md      # Visual architecture
│   └── project-structure.md        # This file
├── src/                            # Source code
│   ├── ansible/                    # Ansible automation
│   │   ├── inventory/              # Host inventories
│   │   │   ├── hosts.example       # Example inventory
│   │   │   └── hosts.ini          # Generated inventory
│   │   └── playbooks/              # Ansible playbooks
│   │       ├── prepare-systems.yml # System preparation
│   │       └── install-kubernetes.yml # K8s installation
│   ├── terraform/                  # Infrastructure as Code
│   │   ├── main.tf                 # Main Terraform config
│   │   ├── variables.tf            # Variable definitions
│   │   ├── outputs.tf              # Output definitions
│   │   └── templates/              # Terraform templates
│   │       └── inventory.tpl       # Ansible inventory template
│   ├── kubernetes/                 # Kubernetes manifests
│   │   ├── namespaces/             # Namespace definitions
│   │   │   ├── all-namespaces.yaml # All namespaces
│   │   │   └── monitoring.yaml     # Monitoring namespaces
│   │   ├── jenkins/                # CI/CD components
│   │   │   └── jenkins-deployment.yaml # Jenkins deployment
│   │   ├── gitops/                 # GitOps management
│   │   │   └── argocd/             # ArgoCD components
│   │   │       └── argocd-install.yaml # ArgoCD installation
│   │   ├── monitoring/             # Observability stack
│   │   │   ├── prometheus-config.yaml # Prometheus config
│   │   │   └── grafana/            # Grafana components
│   │   │       └── grafana-deployment.yaml # Grafana deployment
│   │   ├── artifacts/              # Artifact management
│   │   │   └── artifactory-deployment.yaml # Artifactory deployment
│   │   ├── network/                # Network components
│   │   │   ├── metallb-config.yaml # MetalLB configuration
│   │   │   └── ingress-config.yaml # Ingress configuration
│   │   ├── storage/                # Storage management
│   │   │   └── storage-classes.yaml # Storage classes
│   │   ├── lab-stands/             # Lab applications
│   │   │   └── example-app.yaml    # Example application
│   │   └── nodes/                  # Node management
│   │       └── node-labels.yaml    # Node labeling strategy
│   ├── k8s-manifests/              # Additional K8s manifests (future)
│   ├── modules/                    # Reusable modules (future)
│   ├── utils/                      # Utility scripts
│   │   └── cluster-health-check.sh # Cluster health check utility
│   ├── infrastructure/             # Infrastructure components (future)
│   └── scripts/                    # Deployment scripts
│       ├── deploy-all.sh           # Complete deployment script
│       └── verify-installation.sh  # Installation verification
├── configs/                        # Configuration files
│   ├── terraform.tfvars.example    # Terraform variables example
│   └── ansible.cfg                 # Ansible configuration
├── examples/                       # Example deployments
├── git-hooks/                      # Git hooks
│   └── pre-commit                  # Pre-commit validation
├── test/                           # Testing
│   └── test-manifests.sh           # Manifest validation tests
├── linkers/                        # Code analysis tools
│   └── lint-k8s-manifests.sh       # K8s manifests linter
├── .gitignore                      # Git ignore rules
├── LICENSE                         # Project license
└── README.md                       # Project overview
```

### Component Descriptions

#### 1. **Documentation (`docs/`)**
- **Architecture Overview**: System design and component relationships
- **Installation Guides**: Step-by-step installation instructions
- **Requirements**: Hardware and software requirements
- **Troubleshooting**: Common issues and solutions
- **Diagrams**: Visual representations of architecture

#### 2. **Source Code (`src/`)**
- **Ansible**: Configuration management and automation
- **Terraform**: Infrastructure provisioning
- **Kubernetes**: Application manifests and configurations
- **Scripts**: Deployment and utility scripts
- **Utils**: Helper utilities and tools

#### 3. **Configuration (`configs/`)**
- **Terraform Variables**: Infrastructure configuration
- **Ansible Config**: Automation settings
- **Examples**: Configuration templates

#### 4. **Quality Assurance**
- **Git Hooks**: Pre-commit validation
- **Tests**: Manifest validation and testing
- **Linters**: Code quality analysis

### File Types and Purposes

#### YAML Files (Kubernetes Manifests)
- **Deployments**: Application deployments with resource limits
- **Services**: Network service definitions
- **Ingress**: External access configuration
- **ConfigMaps**: Configuration data
- **Secrets**: Sensitive data management
- **Storage**: Persistent volumes and storage classes
- **Namespaces**: Resource isolation

#### Terraform Files
- **main.tf**: Main infrastructure configuration
- **variables.tf**: Input variable definitions
- **outputs.tf**: Output value definitions
- **templates/**: Template files for dynamic content

#### Ansible Files
- **playbooks/**: Automation playbooks
- **inventory/**: Host definitions and grouping
- **roles/**: Reusable automation components

#### Shell Scripts
- **Deployment**: Automated deployment processes
- **Verification**: Health checks and validation
- **Utilities**: Helper functions and tools

## Русский

### Полная структура проекта

```
k8s-lab-baremetal-architecture/
├── docs/                           # Документация
│   ├── architecture.md             # Обзор архитектуры системы
│   ├── installation.md             # Руководство по установке
│   ├── requirements.md             # Системные требования
│   ├── troubleshooting.md          # Руководство по устранению неполадок
│   ├── installation-guides/        # Детальные руководства по установке
│   │   └── step-by-step-installation.md  # Пошаговая установка
│   ├── diagrams/                   # Диаграммы архитектуры
│   │   └── architecture-overview.md      # Визуальная архитектура
│   └── project-structure.md        # Этот файл
├── src/                            # Исходный код
│   ├── ansible/                    # Ansible автоматизация
│   │   ├── inventory/              # Инвентари хостов
│   │   │   ├── hosts.example       # Пример инвентаря
│   │   │   └── hosts.ini          # Сгенерированный инвентарь
│   │   └── playbooks/              # Ansible плейбуки
│   │       ├── prepare-systems.yml # Подготовка системы
│   │       └── install-kubernetes.yml # Установка K8s
│   ├── terraform/                  # Infrastructure as Code
│   │   ├── main.tf                 # Основная конфигурация Terraform
│   │   ├── variables.tf            # Определения переменных
│   │   ├── outputs.tf              # Определения выходных данных
│   │   └── templates/              # Terraform шаблоны
│   │       └── inventory.tpl       # Шаблон инвентаря Ansible
│   ├── kubernetes/                 # Манифесты Kubernetes
│   │   ├── namespaces/             # Определения namespace
│   │   │   ├── all-namespaces.yaml # Все namespace
│   │   │   └── monitoring.yaml     # Namespace мониторинга
│   │   ├── jenkins/                # CI/CD компоненты
│   │   │   └── jenkins-deployment.yaml # Развертывание Jenkins
│   │   ├── gitops/                 # GitOps управление
│   │   │   └── argocd/             # Компоненты ArgoCD
│   │   │       └── argocd-install.yaml # Установка ArgoCD
│   │   ├── monitoring/             # Стек наблюдаемости
│   │   │   ├── prometheus-config.yaml # Конфигурация Prometheus
│   │   │   └── grafana/            # Компоненты Grafana
│   │   │       └── grafana-deployment.yaml # Развертывание Grafana
│   │   ├── artifacts/              # Управление артефактами
│   │   │   └── artifactory-deployment.yaml # Развертывание Artifactory
│   │   ├── network/                # Сетевые компоненты
│   │   │   ├── metallb-config.yaml # Конфигурация MetalLB
│   │   │   └── ingress-config.yaml # Конфигурация Ingress
│   │   ├── storage/                # Управление хранилищем
│   │   │   └── storage-classes.yaml # Классы хранилищ
│   │   ├── lab-stands/             # Лабораторные приложения
│   │   │   └── example-app.yaml    # Пример приложения
│   │   └── nodes/                  # Управление узлами
│   │       └── node-labels.yaml    # Стратегия маркировки узлов
│   ├── k8s-manifests/              # Дополнительные K8s манифесты (будущее)
│   ├── modules/                    # Переиспользуемые модули (будущее)
│   ├── utils/                      # Утилитарные скрипты
│   │   └── cluster-health-check.sh # Утилита проверки здоровья кластера
│   ├── infrastructure/             # Инфраструктурные компоненты (будущее)
│   └── scripts/                    # Скрипты развертывания
│       ├── deploy-all.sh           # Скрипт полного развертывания
│       └── verify-installation.sh  # Проверка установки
├── configs/                        # Файлы конфигураций
│   ├── terraform.tfvars.example    # Пример переменных Terraform
│   └── ansible.cfg                 # Конфигурация Ansible
├── examples/                       # Примеры развертываний
├── git-hooks/                      # Git хуки
│   └── pre-commit                  # Pre-commit валидация
├── test/                           # Тестирование
│   └── test-manifests.sh           # Тесты валидации манифестов
├── linkers/                        # Инструменты анализа кода
│   └── lint-k8s-manifests.sh       # Линтер манифестов K8s
├── .gitignore                      # Правила игнорирования Git
├── LICENSE                         # Лицензия проекта
└── README.md                       # Обзор проекта
```

### Описания компонентов

#### 1. **Документация (`docs/`)**
- **Обзор архитектуры**: Дизайн системы и отношения компонентов
- **Руководства по установке**: Пошаговые инструкции по установке
- **Требования**: Аппаратные и программные требования
- **Устранение неполадок**: Общие проблемы и решения
- **Диаграммы**: Визуальные представления архитектуры

#### 2. **Исходный код (`src/`)**
- **Ansible**: Управление конфигурациями и автоматизация
- **Terraform**: Подготовка инфраструктуры
- **Kubernetes**: Манифесты приложений и конфигурации
- **Скрипты**: Скрипты развертывания и утилиты
- **Утилиты**: Вспомогательные утилиты и инструменты

#### 3. **Конфигурация (`configs/`)**
- **Переменные Terraform**: Конфигурация инфраструктуры
- **Конфигурация Ansible**: Настройки автоматизации
- **Примеры**: Шаблоны конфигураций

#### 4. **Обеспечение качества**
- **Git хуки**: Pre-commit валидация
- **Тесты**: Валидация манифестов и тестирование
- **Линтеры**: Анализ качества кода

### Типы файлов и назначения

#### YAML файлы (манифесты Kubernetes)
- **Deployments**: Развертывания приложений с лимитами ресурсов
- **Services**: Определения сетевых сервисов
- **Ingress**: Конфигурация внешнего доступа
- **ConfigMaps**: Данные конфигурации
- **Secrets**: Управление чувствительными данными
- **Storage**: Постоянные тома и классы хранилищ
- **Namespaces**: Изоляция ресурсов

#### Terraform файлы
- **main.tf**: Основная конфигурация инфраструктуры
- **variables.tf**: Определения входных переменных
- **outputs.tf**: Определения выходных значений
- **templates/**: Шаблонные файлы для динамического контента

#### Ansible файлы
- **playbooks/**: Плейбуки автоматизации
- **inventory/**: Определения хостов и группировка
- **roles/**: Переиспользуемые компоненты автоматизации

#### Shell скрипты
- **Развертывание**: Автоматизированные процессы развертывания
- **Верификация**: Проверки здоровья и валидация
- **Утилиты**: Вспомогательные функции и инструменты

### Принципы организации

#### 1. **Модульность**
- Каждый компонент в отдельной директории
- Переиспользуемые модули и шаблоны
- Четкое разделение ответственности

#### 2. **Масштабируемость**
- Готовность к расширению
- Поддержка различных окружений
- Конфигурируемость компонентов

#### 3. **Качество кода**
- Автоматизированная проверка качества
- Тестирование всех компонентов
- Документирование всех решений

#### 4. **Безопасность**
- Проверка чувствительных данных
- Валидация конфигураций
- Следование лучшим практикам 