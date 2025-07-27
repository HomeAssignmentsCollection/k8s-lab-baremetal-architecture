# Secrets Management - Управление секретами

## Обзор

Этот модуль обеспечивает безопасное управление секретами в Kubernetes кластере, включая:

- Генерацию безопасных паролей
- Kubernetes Secrets
- External Secrets Operator (опционально)
- Интеграцию с внешними системами управления секретами

## Структура файлов

```
secrets_management/
├── README.md                           # Документация
├── secrets.yaml                        # Базовые секреты (не для продакшена)
├── generated-secrets.yaml              # Автоматически сгенерированные секреты
├── passwords.txt                       # Файл с паролями (удалить после развертывания)
├── generate-secrets.sh                 # Скрипт генерации секретов
└── external-secrets-operator.yaml      # External Secrets Operator
```

## Быстрый старт

### 1. Генерация секретов

```bash
# Генерировать новые секреты
./src/kubernetes/secrets_management/generate-secrets.sh

# Принудительно перегенерировать секреты
./src/kubernetes/secrets_management/generate-secrets.sh --force
```

### 2. Развертывание секретов

```bash
# Развернуть секреты в кластер
kubectl apply -f src/kubernetes/secrets_management/generated-secrets.yaml
```

### 3. Проверка секретов

```bash
# Проверить созданные секреты
kubectl get secrets -A

# Проверить секреты в конкретном namespace
kubectl get secrets -n jenkins
kubectl get secrets -n monitoring
```

## Безопасность

### Важные рекомендации:

1. **Никогда не коммитьте файл `passwords.txt` в git**
2. **Удалите `passwords.txt` после развертывания**
3. **Храните пароли в безопасном месте**
4. **Регулярно ротируйте пароли**
5. **Используйте External Secrets Operator для продакшена**

### Настройка .gitignore

Добавьте в `.gitignore`:

```gitignore
# Secrets management
src/kubernetes/secrets_management/passwords.txt
src/kubernetes/secrets_management/generated-secrets.yaml
```

## Интеграция с приложениями

### Jenkins

Jenkins автоматически использует секреты через переменные окружения:

```yaml
env:
- name: JENKINS_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: jenkins-admin-secret
      key: admin-password
```

### Grafana

Grafana использует секреты для аутентификации:

```yaml
env:
- name: GF_SECURITY_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: grafana-admin-secret
      key: admin-password
```

### ArgoCD

ArgoCD использует секреты для доступа:

```yaml
env:
- name: ARGOCD_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: argocd-admin-secret
      key: admin-password
```

## External Secrets Operator

Для продакшена рекомендуется использовать External Secrets Operator для интеграции с:

- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager

### Установка External Secrets Operator

```bash
# Развернуть External Secrets Operator
kubectl apply -f src/kubernetes/secrets_management/external-secrets-operator.yaml
```

### Настройка Vault

1. Установите HashiCorp Vault
2. Настройте Kubernetes аутентификацию
3. Создайте секреты в Vault
4. Настройте SecretStore и ExternalSecret

## Мониторинг секретов

### Проверка статуса секретов

```bash
# Проверить все секреты
kubectl get secrets -A

# Проверить конкретный секрет
kubectl describe secret jenkins-admin-secret -n jenkins

# Проверить External Secrets
kubectl get externalsecrets -A
```

### Алерты для секретов

Настройте алерты для:
- Истечения срока действия сертификатов
- Неудачных попыток доступа к секретам
- Проблем с External Secrets Operator

## Troubleshooting

### Проблемы с секретами

1. **Секрет не создается**
   ```bash
   kubectl describe secret <secret-name> -n <namespace>
   kubectl get events -n <namespace>
   ```

2. **Приложение не может получить секрет**
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

3. **External Secrets не работает**
   ```bash
   kubectl get externalsecrets -A
   kubectl describe externalsecret <name> -n <namespace>
   kubectl logs -n external-secrets -l app=external-secrets
   ```

### Частые ошибки

- **Permission denied**: Проверьте RBAC права
- **Secret not found**: Убедитесь, что секрет создан в правильном namespace
- **Invalid base64**: Проверьте кодировку секрета

## Обновление секретов

### Ротация паролей

1. Сгенерируйте новые секреты:
   ```bash
   ./src/kubernetes/secrets_management/generate-secrets.sh --force
   ```

2. Примените новые секреты:
   ```bash
   kubectl apply -f src/kubernetes/secrets_management/generated-secrets.yaml
   ```

3. Перезапустите приложения:
   ```bash
   kubectl rollout restart deployment/jenkins -n jenkins
   kubectl rollout restart deployment/grafana -n monitoring
   ```

### Обновление сертификатов

1. Обновите TLS сертификаты в секрете
2. Примените обновленный секрет
3. Перезапустите Ingress контроллер

## Лучшие практики

1. **Используйте разные секреты для разных окружений**
2. **Ограничивайте доступ к секретам через RBAC**
3. **Мониторьте доступ к секретам**
4. **Регулярно ротируйте секреты**
5. **Используйте External Secrets Operator для продакшена**
6. **Шифруйте секреты в etcd**
7. **Логируйте доступ к секретам**

## Ссылки

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) 