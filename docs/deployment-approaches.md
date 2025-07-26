# Deployment Approaches / Подходы к развертыванию

[English](#english) | [Русский](#russian)

## English

This project supports two deployment approaches: **Direct YAML manifests** and **Helm charts**. Both achieve the same result but serve different use cases.

### Approach Comparison

| Aspect | YAML Manifests | Helm Charts |
|--------|----------------|-------------|
| **Complexity** | ✅ Simple and transparent | ⚠️ Additional abstraction layer |
| **Learning Value** | ✅ Excellent for learning Kubernetes | ⚠️ Less transparent for beginners |
| **Maintenance** | ⚠️ Manual version management | ✅ Automated version updates |
| **Flexibility** | ✅ Full control over every detail | ✅ Powerful templating capabilities |
| **Dependencies** | ✅ No external tools required | ⚠️ Requires Helm CLI and repositories |
| **Debugging** | ✅ Easy to trace and troubleshoot | ⚠️ More complex debugging |
| **Production Ready** | ⚠️ Requires manual scaling | ✅ Industry standard for production |
| **Customization** | ✅ Direct editing of manifests | ✅ Values-based configuration |

### When to Use Each Approach

#### Use YAML Manifests When:
- **Learning Kubernetes**: Understanding raw resources and their relationships
- **Simple Deployments**: Small to medium complexity applications
- **Full Control**: Need to customize every aspect of the deployment
- **Minimal Dependencies**: Want to avoid additional tools
- **Debugging**: Need to easily trace and fix issues
- **Educational Purposes**: Teaching Kubernetes concepts

#### Use Helm Charts When:
- **Production Environments**: Industry-standard approach
- **Complex Applications**: Applications with many components
- **Version Management**: Need to easily update and rollback
- **Team Collaboration**: Multiple teams working on the same deployment
- **Environment Consistency**: Deploying to multiple environments
- **Reusability**: Want to reuse configurations across projects

### Quick Start

#### YAML Approach
```bash
# Deploy everything with YAML manifests
./src/scripts/deploy-all.sh
```

#### Helm Approach
```bash
# Install Helm (if not already installed)
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/

# Deploy everything with Helm charts
./src/scripts/deploy-helm.sh
```

### Migration Path

You can start with either approach and migrate later:

1. **Start with YAML**: Learn Kubernetes fundamentals, then migrate to Helm
2. **Start with Helm**: Use industry standards from the beginning
3. **Hybrid Approach**: Use YAML for simple components, Helm for complex ones

### File Structure

```
src/
├── kubernetes/          # YAML manifests (primary approach)
│   ├── jenkins/
│   ├── gitops/
│   ├── monitoring/
│   └── ...
└── helm/               # Helm charts (optional alternative)
    ├── charts/
    │   ├── jenkins/
    │   ├── argocd/
    │   ├── monitoring/
    │   └── artifactory/
    └── README.md
```

## Русский

Этот проект поддерживает два подхода к развертыванию: **Прямые YAML манифесты** и **Helm чарты**. Оба достигают одинакового результата, но служат разным целям.

### Сравнение подходов

| Аспект | YAML манифесты | Helm чарты |
|--------|----------------|-------------|
| **Сложность** | ✅ Простота и прозрачность | ⚠️ Дополнительный слой абстракции |
| **Обучающая ценность** | ✅ Отлично для изучения Kubernetes | ⚠️ Менее прозрачно для начинающих |
| **Обслуживание** | ⚠️ Ручное управление версиями | ✅ Автоматические обновления версий |
| **Гибкость** | ✅ Полный контроль над деталями | ✅ Мощные возможности шаблонизации |
| **Зависимости** | ✅ Не требуются внешние инструменты | ⚠️ Требует Helm CLI и репозитории |
| **Отладка** | ✅ Легко отслеживать и исправлять | ⚠️ Более сложная отладка |
| **Готовность к продакшену** | ⚠️ Требует ручного масштабирования | ✅ Индустриальный стандарт |
| **Настройка** | ✅ Прямое редактирование манифестов | ✅ Конфигурация через values |

### Когда использовать каждый подход

#### Используйте YAML манифесты когда:
- **Изучаете Kubernetes**: Понимание сырых ресурсов и их связей
- **Простые развертывания**: Приложения малой и средней сложности
- **Полный контроль**: Нужно настроить каждый аспект развертывания
- **Минимальные зависимости**: Хотите избежать дополнительных инструментов
- **Отладка**: Нужно легко отслеживать и исправлять проблемы
- **Образовательные цели**: Обучение концепциям Kubernetes

#### Используйте Helm чарты когда:
- **Продакшен окружения**: Индустриальный стандарт
- **Сложные приложения**: Приложения со многими компонентами
- **Управление версиями**: Нужно легко обновлять и откатывать
- **Командная работа**: Несколько команд работают над одним развертыванием
- **Консистентность окружений**: Развертывание в нескольких окружениях
- **Переиспользование**: Хотите переиспользовать конфигурации

### Быстрый старт

#### YAML подход
```bash
# Развернуть все с YAML манифестами
./src/scripts/deploy-all.sh
```

#### Helm подход
```bash
# Установить Helm (если не установлен)
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/

# Развернуть все с Helm чартами
./src/scripts/deploy-helm.sh
```

### Путь миграции

Можете начать с любого подхода и мигрировать позже:

1. **Начать с YAML**: Изучить основы Kubernetes, затем мигрировать к Helm
2. **Начать с Helm**: Использовать индустриальные стандарты с самого начала
3. **Гибридный подход**: Использовать YAML для простых компонентов, Helm для сложных

### Структура файлов

```
src/
├── kubernetes/          # YAML манифесты (основной подход)
│   ├── jenkins/
│   ├── gitops/
│   ├── monitoring/
│   └── ...
└── helm/               # Helm чарты (опциональная альтернатива)
    ├── charts/
    │   ├── jenkins/
    │   ├── argocd/
    │   ├── monitoring/
    │   └── artifactory/
    └── README.md
``` 