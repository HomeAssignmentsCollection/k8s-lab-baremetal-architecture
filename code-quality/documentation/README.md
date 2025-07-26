# Code Quality Tools

[English](#english) | [Русский](#russian)

## English

This directory contains comprehensive code quality tools and configurations for the Kubernetes Baremetal Lab project. The tools ensure code consistency, security, and best practices across all project components.

## Directory Structure

```
code-quality/
├── linters/                 # Linting tools for different file types
│   ├── lint-k8s-manifests.sh    # Kubernetes manifest validation
│   ├── lint-terraform.sh        # Terraform configuration validation
│   ├── lint-ansible.sh          # Ansible playbook validation
│   └── lint-shell.sh            # Shell script validation
├── pre-commit-hooks/        # Git pre-commit hooks
│   ├── pre-commit              # Main pre-commit hook script
│   └── pre-commit-config.yaml  # Pre-commit configuration
├── test-tools/             # Testing and validation tools
│   ├── test-manifests.sh       # Kubernetes manifest testing
│   └── run-all-checks.sh       # Comprehensive quality check runner
├── configs/                # Configuration files for linting tools
│   ├── .shellcheckrc           # ShellCheck configuration
│   ├── .ansible-lint.yml       # Ansible-lint configuration
│   ├── .tflint.hcl             # TFLint configuration
│   ├── .yamllint               # YAML linting configuration
│   └── .markdownlint.json      # Markdown linting configuration
└── documentation/          # Documentation for code quality tools
    └── README.md              # This file
```

## Tools Overview

### Linters

#### Kubernetes Manifest Linter (`lint-k8s-manifests.sh`)
- Validates Kubernetes YAML syntax
- Checks for best practices
- Ensures proper resource definitions
- Validates against Kubernetes schema

#### Terraform Linter (`lint-terraform.sh`)
- Validates Terraform syntax
- Checks for security issues
- Ensures best practices
- Runs TFLint for enhanced validation

#### Ansible Linter (`lint-ansible.sh`)
- Validates Ansible playbook syntax
- Checks for security issues
- Ensures best practices
- Validates inventory files

#### Shell Script Linter (`lint-shell.sh`)
- Validates shell script syntax
- Checks for security issues
- Ensures portability
- Runs ShellCheck for enhanced validation

### Pre-commit Hooks

#### Main Pre-commit Hook (`pre-commit`)
- Runs before each commit
- Validates all changed files
- Ensures code quality standards
- Prevents problematic commits

#### Pre-commit Configuration (`pre-commit-config.yaml`)
- Configures all pre-commit hooks
- Defines rules and exclusions
- Sets up external tools integration
- Manages hook execution order

### Test Tools

#### Manifest Testing (`test-manifests.sh`)
- Tests Kubernetes manifests
- Validates against live cluster
- Checks resource creation
- Ensures proper configuration

#### Comprehensive Check Runner (`run-all-checks.sh`)
- Runs all quality checks
- Provides summary reports
- Tracks check results
- Generates recommendations

### Configuration Files

#### ShellCheck Configuration (`.shellcheckrc`)
- Configures ShellCheck rules
- Disables acceptable warnings
- Sets shell type
- Defines external sources

#### Ansible-lint Configuration (`.ansible-lint.yml`)
- Configures Ansible-lint rules
- Defines skip and warn lists
- Sets output format
- Manages exclusions

#### TFLint Configuration (`.tflint.hcl`)
- Configures TFLint rules
- Enables cloud provider plugins
- Sets naming conventions
- Defines custom rules

## Usage

### Running Individual Checks

```bash
# Run Kubernetes manifest validation
bash code-quality/linters/lint-k8s-manifests.sh

# Run Terraform validation
bash code-quality/linters/lint-terraform.sh

# Run Ansible validation
bash code-quality/linters/lint-ansible.sh

# Run shell script validation
bash code-quality/linters/lint-shell.sh
```

### Running All Checks

```bash
# Run comprehensive quality check
bash code-quality/test-tools/run-all-checks.sh
```

### Setting Up Pre-commit Hooks

```bash
# Install pre-commit hooks
cp code-quality/pre-commit-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Or use pre-commit framework
pip install pre-commit
pre-commit install
```

### Installing Required Tools

```bash
# Install ShellCheck
sudo apt install shellcheck  # Ubuntu/Debian
sudo yum install shellcheck  # CentOS/RHEL
brew install shellcheck      # macOS

# Install TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install Ansible-lint
pip install ansible-lint

# Install YAML lint
pip install yamllint

# Install pre-commit
pip install pre-commit
```

## Configuration

### Customizing Linting Rules

Each linter has its own configuration file in the `configs/` directory:

- **ShellCheck**: Edit `.shellcheckrc` to modify shell script linting rules
- **Ansible-lint**: Edit `.ansible-lint.yml` to modify Ansible linting rules
- **TFLint**: Edit `.tflint.hcl` to modify Terraform linting rules

### Adding New Checks

To add a new quality check:

1. Create a new script in the appropriate directory
2. Add it to the pre-commit configuration
3. Update the comprehensive check runner
4. Document the new check

### Excluding Files

To exclude files from quality checks:

1. Add patterns to the appropriate configuration file
2. Update pre-commit configuration exclusions
3. Modify individual linter scripts as needed

## Best Practices

### Code Quality Standards

1. **Consistency**: Use consistent formatting and naming conventions
2. **Documentation**: Include proper documentation for all code
3. **Security**: Follow security best practices
4. **Performance**: Optimize for performance where appropriate
5. **Maintainability**: Write maintainable and readable code

### Git Workflow

1. **Pre-commit**: Always run pre-commit hooks before committing
2. **Code Review**: Review code changes thoroughly
3. **Testing**: Test changes before committing
4. **Documentation**: Update documentation as needed

### Continuous Integration

1. **Automated Checks**: Set up automated quality checks in CI/CD
2. **Quality Gates**: Use quality checks as gates for deployment
3. **Reporting**: Generate and review quality reports
4. **Improvement**: Continuously improve quality standards

## Troubleshooting

### Common Issues

#### Pre-commit Hooks Not Running
```bash
# Check if hooks are installed
ls -la .git/hooks/pre-commit

# Reinstall hooks
cp code-quality/pre-commit-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

#### Linter Not Found
```bash
# Check if tool is installed
which shellcheck
which tflint
which ansible-lint

# Install missing tools
# See installation instructions above
```

#### Configuration Issues
```bash
# Check configuration files
cat code-quality/configs/.shellcheckrc
cat code-quality/configs/.ansible-lint.yml
cat code-quality/configs/.tflint.hcl
```

### Getting Help

1. Check the tool documentation
2. Review configuration files
3. Run tools with verbose output
4. Check for common issues in this documentation

## Contributing

When contributing to code quality tools:

1. Follow existing patterns and conventions
2. Add proper documentation
3. Test changes thoroughly
4. Update configuration files as needed
5. Ensure backward compatibility

## Русский

Эта директория содержит комплексные инструменты качества кода и конфигурации для проекта Kubernetes Baremetal Lab. Инструменты обеспечивают согласованность кода, безопасность и лучшие практики во всех компонентах проекта.

## Структура директории

```
code-quality/
├── linters/                 # Инструменты линтинга для разных типов файлов
│   ├── lint-k8s-manifests.sh    # Валидация манифестов Kubernetes
│   ├── lint-terraform.sh        # Валидация конфигурации Terraform
│   ├── lint-ansible.sh          # Валидация плейбуков Ansible
│   └── lint-shell.sh            # Валидация shell скриптов
├── pre-commit-hooks/        # Git pre-commit хуки
│   ├── pre-commit              # Основной pre-commit хук
│   └── pre-commit-config.yaml  # Конфигурация pre-commit
├── test-tools/             # Инструменты тестирования и валидации
│   ├── test-manifests.sh       # Тестирование манифестов Kubernetes
│   └── run-all-checks.sh       # Комплексный запуск проверок качества
├── configs/                # Файлы конфигурации для инструментов линтинга
│   ├── .shellcheckrc           # Конфигурация ShellCheck
│   ├── .ansible-lint.yml       # Конфигурация Ansible-lint
│   ├── .tflint.hcl             # Конфигурация TFLint
│   ├── .yamllint               # Конфигурация YAML линтинга
│   └── .markdownlint.json      # Конфигурация Markdown линтинга
└── documentation/          # Документация для инструментов качества кода
    └── README.md              # Этот файл
```

## Обзор инструментов

### Линтеры

#### Линтер манифестов Kubernetes (`lint-k8s-manifests.sh`)
- Валидирует синтаксис YAML Kubernetes
- Проверяет лучшие практики
- Обеспечивает правильные определения ресурсов
- Валидирует против схемы Kubernetes

#### Линтер Terraform (`lint-terraform.sh`)
- Валидирует синтаксис Terraform
- Проверяет проблемы безопасности
- Обеспечивает лучшие практики
- Запускает TFLint для расширенной валидации

#### Линтер Ansible (`lint-ansible.sh`)
- Валидирует синтаксис плейбуков Ansible
- Проверяет проблемы безопасности
- Обеспечивает лучшие практики
- Валидирует файлы инвентаря

#### Линтер shell скриптов (`lint-shell.sh`)
- Валидирует синтаксис shell скриптов
- Проверяет проблемы безопасности
- Обеспечивает переносимость
- Запускает ShellCheck для расширенной валидации

### Pre-commit хуки

#### Основной pre-commit хук (`pre-commit`)
- Запускается перед каждым коммитом
- Валидирует все измененные файлы
- Обеспечивает стандарты качества кода
- Предотвращает проблемные коммиты

#### Конфигурация pre-commit (`pre-commit-config.yaml`)
- Конфигурирует все pre-commit хуки
- Определяет правила и исключения
- Настраивает интеграцию внешних инструментов
- Управляет порядком выполнения хуков

### Инструменты тестирования

#### Тестирование манифестов (`test-manifests.sh`)
- Тестирует манифесты Kubernetes
- Валидирует против живого кластера
- Проверяет создание ресурсов
- Обеспечивает правильную конфигурацию

#### Комплексный запуск проверок (`run-all-checks.sh`)
- Запускает все проверки качества
- Предоставляет сводные отчеты
- Отслеживает результаты проверок
- Генерирует рекомендации

### Файлы конфигурации

#### Конфигурация ShellCheck (`.shellcheckrc`)
- Конфигурирует правила ShellCheck
- Отключает приемлемые предупреждения
- Устанавливает тип shell
- Определяет внешние источники

#### Конфигурация Ansible-lint (`.ansible-lint.yml`)
- Конфигурирует правила Ansible-lint
- Определяет списки пропуска и предупреждений
- Устанавливает формат вывода
- Управляет исключениями

#### Конфигурация TFLint (`.tflint.hcl`)
- Конфигурирует правила TFLint
- Включает плагины облачных провайдеров
- Устанавливает соглашения об именовании
- Определяет пользовательские правила

## Использование

### Запуск отдельных проверок

```bash
# Запуск валидации манифестов Kubernetes
bash code-quality/linters/lint-k8s-manifests.sh

# Запуск валидации Terraform
bash code-quality/linters/lint-terraform.sh

# Запуск валидации Ansible
bash code-quality/linters/lint-ansible.sh

# Запуск валидации shell скриптов
bash code-quality/linters/lint-shell.sh
```

### Запуск всех проверок

```bash
# Запуск комплексной проверки качества
bash code-quality/test-tools/run-all-checks.sh
```

### Настройка pre-commit хуков

```bash
# Установка pre-commit хуков
cp code-quality/pre-commit-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Или использование pre-commit фреймворка
pip install pre-commit
pre-commit install
```

### Установка необходимых инструментов

```bash
# Установка ShellCheck
sudo apt install shellcheck  # Ubuntu/Debian
sudo yum install shellcheck  # CentOS/RHEL
brew install shellcheck      # macOS

# Установка TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Установка Ansible-lint
pip install ansible-lint

# Установка YAML lint
pip install yamllint

# Установка pre-commit
pip install pre-commit
```

## Конфигурация

### Настройка правил линтинга

Каждый линтер имеет свой собственный файл конфигурации в директории `configs/`:

- **ShellCheck**: Редактируйте `.shellcheckrc` для изменения правил линтинга shell скриптов
- **Ansible-lint**: Редактируйте `.ansible-lint.yml` для изменения правил линтинга Ansible
- **TFLint**: Редактируйте `.tflint.hcl` для изменения правил линтинга Terraform

### Добавление новых проверок

Для добавления новой проверки качества:

1. Создайте новый скрипт в соответствующей директории
2. Добавьте его в конфигурацию pre-commit
3. Обновите комплексный запуск проверок
4. Документируйте новую проверку

### Исключение файлов

Для исключения файлов из проверок качества:

1. Добавьте паттерны в соответствующий файл конфигурации
2. Обновите исключения конфигурации pre-commit
3. Измените отдельные скрипты линтеров по необходимости

## Лучшие практики

### Стандарты качества кода

1. **Согласованность**: Используйте согласованное форматирование и соглашения об именовании
2. **Документация**: Включайте правильную документацию для всего кода
3. **Безопасность**: Следуйте лучшим практикам безопасности
4. **Производительность**: Оптимизируйте для производительности где это уместно
5. **Поддерживаемость**: Пишите поддерживаемый и читаемый код

### Git workflow

1. **Pre-commit**: Всегда запускайте pre-commit хуки перед коммитом
2. **Code Review**: Тщательно проверяйте изменения кода
3. **Тестирование**: Тестируйте изменения перед коммитом
4. **Документация**: Обновляйте документацию по необходимости

### Непрерывная интеграция

1. **Автоматизированные проверки**: Настройте автоматизированные проверки качества в CI/CD
2. **Quality Gates**: Используйте проверки качества как ворота для развертывания
3. **Отчетность**: Генерируйте и проверяйте отчеты качества
4. **Улучшение**: Постоянно улучшайте стандарты качества

## Устранение неполадок

### Общие проблемы

#### Pre-commit хуки не запускаются
```bash
# Проверьте, установлены ли хуки
ls -la .git/hooks/pre-commit

# Переустановите хуки
cp code-quality/pre-commit-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

#### Линтер не найден
```bash
# Проверьте, установлен ли инструмент
which shellcheck
which tflint
which ansible-lint

# Установите отсутствующие инструменты
# См. инструкции по установке выше
```

#### Проблемы конфигурации
```bash
# Проверьте файлы конфигурации
cat code-quality/configs/.shellcheckrc
cat code-quality/configs/.ansible-lint.yml
cat code-quality/configs/.tflint.hcl
```

### Получение помощи

1. Проверьте документацию инструмента
2. Просмотрите файлы конфигурации
3. Запустите инструменты с подробным выводом
4. Проверьте общие проблемы в этой документации

## Вклад в проект

При внесении вклада в инструменты качества кода:

1. Следуйте существующим паттернам и соглашениям
2. Добавляйте правильную документацию
3. Тщательно тестируйте изменения
4. Обновляйте файлы конфигурации по необходимости
5. Обеспечивайте обратную совместимость 