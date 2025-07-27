# Code Quality Tools

## Description

В этом каталоге собраны инструменты и скрипты для обеспечения качества кода, линтинга, тестирования и автоматизации проверок для всех компонентов проекта.

## Quick installation of all tools

Для быстрой установки всех необходимых утилит используйте скрипт:

```bash
sudo ./code-quality/install-code-quality-tools.sh
```

- Скрипт установит: yamllint, yq, tflint, ansible, ansible-lint, markdownlint-cli, pre-commit.
- Требует права sudo для глобальных утилит (npm, wget в /usr/local/bin).
- После установки рекомендуется перезапустить терминал или выполнить `hash -r` для обновления PATH.

## Manual installation of missing tools

Если хотите установить вручную, используйте инструкции ниже:

### 1. tflint (Terraform Linter)
- [Документация](https://github.com/terraform-linters/tflint)
- Установка:
  ```bash
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
  # или
  sudo apt install tflint
  ```

### 2. ansible and ansible-lint
- [Документация](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Установка:
  ```bash
  pip install ansible ansible-lint
  # или
  sudo apt install ansible ansible-lint
  ```

### 3. yamllint
- [Документация](https://yamllint.readthedocs.io/)
- Установка:
  ```bash
  pip install yamllint
  # или
  sudo apt install yamllint
  ```

### 4. yq
- [Документация](https://github.com/mikefarah/yq)
- Установка:
  ```bash
  sudo wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  sudo chmod +x /usr/local/bin/yq
  ```

### 5. markdownlint
- [Документация](https://github.com/igorshubovych/markdownlint-cli)
- Установка:
  ```bash
  npm install -g markdownlint-cli
  ```

### 6. pre-commit
- [Документация](https://pre-commit.com/)
- Установка:
  ```bash
  pip install pre-commit
  # или
  sudo apt install pre-commit
  ```

## Quick start

1. Установите все необходимые инструменты (см. выше).
2. Проверьте pre-commit хуки:
   ```bash
   pre-commit install
   pre-commit run --all-files
   ```
3. Запустите все проверки:
   ```bash
   ./code-quality/test-tools/run-all-checks.sh
   ```

## Troubleshooting

- Если какой-либо инструмент не установлен — соответствующая проверка будет пропущена или завершится с ошибкой.
- Для корректной работы yamllint создайте файл конфигурации: `code-quality/configs/.yamllint`.
- Для tflint рекомендуется настроить правила под ваш стиль.

## Links
- [tflint](https://github.com/terraform-linters/tflint)
- [ansible-lint](https://ansible-lint.readthedocs.io/)
- [yamllint](https://yamllint.readthedocs.io/)
- [yq](https://github.com/mikefarah/yq)
- [markdownlint](https://github.com/igorshubovych/markdownlint-cli)
- [pre-commit](https://pre-commit.com/) 