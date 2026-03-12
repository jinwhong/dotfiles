#!/bin/bash
# 파일 수정 후 린트 자동 실행 (PostToolUse Edit|Write)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

EXTENSION="${FILE_PATH##*.}"

# 프로젝트 루트 찾기 (가장 가까운 .git 디렉토리 기준)
find_project_root() {
  local dir=$(dirname "$1")
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  echo ""
}

PROJECT_ROOT=$(find_project_root "$FILE_PATH")

case "$EXTENSION" in
  py)
    # ruff: 프로젝트 venv → 글로벌 순서로 탐색
    RUFF=""
    if [ -n "$PROJECT_ROOT" ] && [ -x "$PROJECT_ROOT/.venv/bin/ruff" ]; then
      RUFF="$PROJECT_ROOT/.venv/bin/ruff"
    elif command -v ruff &> /dev/null; then
      RUFF="ruff"
    fi
    if [ -n "$RUFF" ]; then
      RESULT=$($RUFF check "$FILE_PATH" --no-fix 2>&1)
      if [ $? -ne 0 ]; then
        echo "ruff lint issues in $(basename "$FILE_PATH"):"
        echo "$RESULT" | head -20
      fi
    fi
    ;;

  ts|tsx|js|jsx)
    # eslint: 프로젝트 node_modules에서 탐색
    ESLINT=""
    if [ -n "$PROJECT_ROOT" ] && [ -x "$PROJECT_ROOT/node_modules/.bin/eslint" ]; then
      ESLINT="$PROJECT_ROOT/node_modules/.bin/eslint"
    fi
    if [ -n "$ESLINT" ]; then
      RESULT=$($ESLINT "$FILE_PATH" --no-error-on-unmatched-pattern --format compact 2>&1)
      if [ $? -ne 0 ]; then
        echo "eslint issues in $(basename "$FILE_PATH"):"
        echo "$RESULT" | head -20
      fi
    fi
    ;;

  go)
    if command -v go &> /dev/null; then
      DIR=$(dirname "$FILE_PATH")
      RESULT=$(cd "$DIR" && go vet ./... 2>&1)
      if [ $? -ne 0 ]; then
        echo "go vet issues:"
        echo "$RESULT" | head -20
      fi
    fi
    ;;
esac

exit 0
