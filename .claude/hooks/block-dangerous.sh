#!/bin/bash
# 위험한 명령어 차단 (PreToolUse Bash)
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 패턴 매칭: 위험 명령어
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+)?/($|\s)'; then
  echo "BLOCKED: 루트 삭제 명령어입니다." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'git\s+push\s+(-f|--force)\s+(origin\s+)?(main|master)'; then
  echo "BLOCKED: main/master 브랜치 force push는 금지입니다." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'git\s+push\s+(origin\s+)?(main|master)\s+(-f|--force)'; then
  echo "BLOCKED: main/master 브랜치 force push는 금지입니다." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qiE '(DROP\s+(DATABASE|TABLE|SCHEMA))\s'; then
  echo "BLOCKED: DB 삭제 명령어입니다. 정말 필요하면 사용자에게 확인하세요." >&2
  exit 2
fi

exit 0
