#!/bin/bash
# 서버 시작 전 포트 충돌 감지 (PreToolUse Bash)
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 서버 실행 명령어인지 판별
if ! echo "$COMMAND" | grep -qiE '(npm\s+(run\s+)?(dev|start)|yarn\s+(run\s+)?dev|pnpm\s+(run\s+)?dev|vite|uvicorn|gunicorn|flask\s+run|python.*runserver|go\s+run|next\s+dev|tsx\s|node.*serv|streamlit\s+run)'; then
  exit 0
fi

# 명령어에서 포트 추출 시도
PORT=""

# --port N, --port=N, -p N 패턴
EXTRACTED=$(echo "$COMMAND" | grep -oE '(--port|--p|-p)\s*[=]?\s*([0-9]+)' | grep -oE '[0-9]+' | tail -1)
if [ -n "$EXTRACTED" ]; then
  PORT="$EXTRACTED"
fi

# :PORT 패턴 (예: 0.0.0.0:8000)
if [ -z "$PORT" ]; then
  EXTRACTED=$(echo "$COMMAND" | grep -oE ':[0-9]{4,5}' | grep -oE '[0-9]+' | tail -1)
  if [ -n "$EXTRACTED" ]; then
    PORT="$EXTRACTED"
  fi
fi

# 도구별 기본 포트 추정
if [ -z "$PORT" ]; then
  if echo "$COMMAND" | grep -qiE 'vite|npm\s+(run\s+)?dev'; then
    PORT="5173"
  elif echo "$COMMAND" | grep -qiE 'uvicorn|fastapi'; then
    PORT="8000"
  elif echo "$COMMAND" | grep -qiE 'next\s+dev'; then
    PORT="3000"
  elif echo "$COMMAND" | grep -qiE 'flask'; then
    PORT="5000"
  elif echo "$COMMAND" | grep -qiE 'streamlit'; then
    PORT="8501"
  elif echo "$COMMAND" | grep -qiE 'django|runserver'; then
    PORT="8000"
  fi
fi

# 포트 사용 여부 확인
if [ -n "$PORT" ]; then
  PID=$(lsof -ti :"$PORT" 2>/dev/null | head -1)
  if [ -n "$PID" ]; then
    PROCESS_INFO=$(ps -p "$PID" -o pid=,command= 2>/dev/null | head -1)
    echo "PORT CONFLICT: 포트 $PORT이 이미 사용 중입니다." >&2
    echo "PID $PID: $PROCESS_INFO" >&2
    echo "'kill $PID'로 종료하거나, 다른 포트(--port XXXX)를 사용하세요." >&2
    exit 2
  fi
fi

exit 0
