#!/bin/bash
set -euo pipefail

PID_FILE="/tmp/claude_meeting.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "ERROR: No recording in progress (PID file not found)"
    exit 1
fi

PID=$(cat "$PID_FILE")

if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "WARNING: Recording process (PID: $PID) is not running. It may have stopped unexpectedly."
    rm -f "$PID_FILE"
    # Check if wav file exists anyway
    if [ -f "/tmp/claude_meeting.wav" ]; then
        echo "Recording file exists at /tmp/claude_meeting.wav"
        exit 0
    else
        echo "ERROR: No recording file found either."
        exit 1
    fi
fi

# Send SIGINT to ffmpeg for graceful shutdown (finalizes the WAV header)
kill -INT "$PID" 2>/dev/null || true

# Wait for ffmpeg to finish (up to 5 seconds)
for i in $(seq 1 10); do
    if ! ps -p "$PID" > /dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

# Force kill if still running
if ps -p "$PID" > /dev/null 2>&1; then
    echo "WARNING: ffmpeg didn't stop gracefully, force killing..."
    kill -9 "$PID" 2>/dev/null || true
    sleep 0.5
fi

# Verify recording file
if [ -f "/tmp/claude_meeting.wav" ]; then
    FILE_SIZE=$(du -h "/tmp/claude_meeting.wav" | cut -f1)
    echo "Recording stopped successfully"
    echo "  File: /tmp/claude_meeting.wav"
    echo "  Size: ${FILE_SIZE}"
else
    echo "ERROR: Recording file not found at /tmp/claude_meeting.wav"
    exit 1
fi
