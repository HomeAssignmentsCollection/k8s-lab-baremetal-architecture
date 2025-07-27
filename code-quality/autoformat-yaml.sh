#!/bin/bash
# Script for mass auto-formatting YAML files in the project
# Requires: yq (https://github.com/mikefarah/yq), sed
# Usage: ./code-quality/autoformat-yaml.sh [directory]

set -euo pipefail

TARGET_DIR="${1:-.}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${NC}"
}

# Check for yq availability
if ! command -v yq &> /dev/null; then
  print_status "$RED" "[ERROR] yq required (https://github.com/mikefarah/yq)"
  exit 1
fi

# Find all yaml/yml files
YAML_FILES=$(find "$TARGET_DIR" \( -name "*.yaml" -o -name "*.yml" \) -type f)

for file in $YAML_FILES; do
  print_status "$YELLOW" "Formatting: $file"
  # 1. Remove trailing spaces
  sed -i 's/[ \t]*$//' "$file"
  # 2. Add newline at end of file
  echo "" >> "$file"
  # 3. Add '---' at beginning if not present
  first_line=$(head -n 1 "$file")
  if [[ "$first_line" != '---' ]]; then
    sed -i '1s/^/---\n/' "$file"
  fi
  # 4. Apply yq for auto-indentation (overwrite file)
  yq eval '.' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  print_status "$GREEN" "✓ $file formatted"
done

print_status "$GREEN" "\nМассовое автоформатирование YAML завершено!"
print_status "$YELLOW" "Рекомендуется повторно запустить yamllint для контроля." 