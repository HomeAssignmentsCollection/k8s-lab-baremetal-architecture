#!/bin/bash
# Скрипт для установки всех необходимых инструментов для проверки качества кода
# Устанавливает: yamllint, yq, tflint, ansible, ansible-lint, markdownlint-cli, pre-commit
# Запускать с правами sudo для глобальных утилит (npm, wget в /usr/local/bin)
# Usage: sudo ./code-quality/install-code-quality-tools.sh

set -euo pipefail

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# RED='\033[0;31m'  # Unused color variable
NC='\033[0m'

print_status() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${NC}"
}

print_status "$YELLOW" "Установка yamllint (Python)..."
pip install --user yamllint || sudo apt install -y yamllint

print_status "$YELLOW" "Установка yq (YAML CLI)..."
wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x /usr/local/bin/yq

print_status "$YELLOW" "Установка tflint (Terraform Linter)..."
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

print_status "$YELLOW" "Установка ansible и ansible-lint..."
pip install --user ansible ansible-lint || sudo apt install -y ansible ansible-lint

print_status "$YELLOW" "Установка npm и markdownlint-cli..."
sudo apt update && sudo apt install -y npm
npm install -g markdownlint-cli

print_status "$YELLOW" "Установка pre-commit..."
pip install --user pre-commit || sudo apt install -y pre-commit

print_status "$GREEN" "\nВсе инструменты для проверки кода успешно установлены!"
print_status "$YELLOW" "Рекомендуется перезапустить терминал или выполнить 'hash -r' для обновления PATH." 