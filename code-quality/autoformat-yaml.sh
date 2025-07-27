#!/bin/bash
# Скрипт для массового автоформатирования YAML-файлов в проекте
# Требует: yq (https://github.com/mikefarah/yq), sed
# Usage: ./code-quality/autoformat-yaml.sh [директория]

set -euo pipefail

TARGET_DIR="${1:-.}"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${NC}"
}

# Проверка наличия yq
if ! command -v yq &> /dev/null; then
  print_status "$RED" "[ERROR] Требуется yq (https://github.com/mikefarah/yq)"
  exit 1
fi

# Поиск всех yaml/yml файлов
YAML_FILES=$(find "$TARGET_DIR" \( -name "*.yaml" -o -name "*.yml" \) -type f)

for file in $YAML_FILES; do
  print_status "$YELLOW" "Форматирую: $file"
  # 1. Удалить trailing spaces
  sed -i 's/[ \t]*$//' "$file"
  # 2. Добавить новую строку в конец файла
  echo "" >> "$file"
  # 3. Добавить '---' в начало, если нет
  first_line=$(head -n 1 "$file")
  if [[ "$first_line" != '---' ]]; then
    sed -i '1s/^/---\n/' "$file"
  fi
  # 4. Применить yq для автоотступов (перезаписать файл)
  yq eval '.' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  print_status "$GREEN" "✓ $file отформатирован"
done

print_status "$GREEN" "\nМассовое автоформатирование YAML завершено!"
print_status "$YELLOW" "Рекомендуется повторно запустить yamllint для контроля." 