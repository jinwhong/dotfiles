#!/bin/bash
set -euo pipefail

PID_FILE="/tmp/claude_meeting.pid"
META_FILE="/tmp/claude_meeting.meta"
WAV_FILE="/tmp/claude_meeting.wav"

# Check if already recording
if [ -f "$PID_FILE" ]; then
    if ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
        echo "ERROR: A recording is already in progress (PID: $(cat "$PID_FILE"))"
        exit 1
    else
        echo "Stale PID file found, cleaning up..."
        rm -f "$PID_FILE" "$META_FILE"
    fi
fi

# Check ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "ERROR: ffmpeg is not installed. Run /meeting-setup for installation guidance."
    exit 1
fi

# Detect audio devices
DEVICES=$(ffmpeg -f avfoundation -list_devices true -i "" 2>&1 || true)

# Parse device indices — extract [N] from AVFoundation output lines
parse_index() {
    echo "$1" | grep -oE '\[[0-9]+\]' | head -1 | tr -d '[]' || true
}

BLACKHOLE_INDEX=""
FIRST_AUDIO_INDEX=""
FIRST_AUDIO_NAME=""
AUDIO_SECTION=false

while IFS= read -r line; do
    if echo "$line" | grep -q "AVFoundation audio devices"; then
        AUDIO_SECTION=true
        continue
    fi
    if [ "$AUDIO_SECTION" = true ]; then
        INDEX=$(parse_index "$line")
        if [ -n "$INDEX" ]; then
            if echo "$line" | grep -qi "blackhole"; then
                BLACKHOLE_INDEX="$INDEX"
            elif [ -z "$FIRST_AUDIO_INDEX" ]; then
                # First non-BlackHole audio device = macOS active input device
                FIRST_AUDIO_INDEX="$INDEX"
                FIRST_AUDIO_NAME=$(echo "$line" | sed 's/.*\] //')
            fi
        fi
    fi
done <<< "$DEVICES"

# Determine recording configuration
# Priority: BlackHole > first audio device (macOS puts active input at index 0)
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
DEVICES_USED=""

if [ -n "$BLACKHOLE_INDEX" ]; then
    # Record system audio via BlackHole
    AUDIO_INPUT=":${BLACKHOLE_INDEX}"
    DEVICES_USED="BlackHole (system audio), index=${BLACKHOLE_INDEX}"
elif [ -n "$FIRST_AUDIO_INDEX" ]; then
    # Use the first (active) audio input device
    AUDIO_INPUT=":${FIRST_AUDIO_INDEX}"
    DEVICES_USED="${FIRST_AUDIO_NAME}, index=${FIRST_AUDIO_INDEX}"
else
    # Last resort: try default audio input (index 0)
    AUDIO_INPUT=":0"
    DEVICES_USED="Default audio input, index=0"
fi

# Start recording in background
ffmpeg -f avfoundation -i "$AUDIO_INPUT" \
    -acodec pcm_s16le -ar 16000 -ac 1 \
    -y "$WAV_FILE" \
    </dev/null >/dev/null 2>&1 &
FFMPEG_PID=$!

# Wait a moment to check if ffmpeg started successfully
sleep 1

if ! ps -p "$FFMPEG_PID" > /dev/null 2>&1; then
    echo "ERROR: ffmpeg failed to start. Check audio device availability."
    echo "Available devices:"
    echo "$DEVICES"
    exit 1
fi

# Save PID and metadata
echo "$FFMPEG_PID" > "$PID_FILE"

cat > "$META_FILE" <<EOF
start_time=${START_TIME}
devices=${DEVICES_USED}
wav_file=${WAV_FILE}
pid=${FFMPEG_PID}
EOF

echo "Recording started successfully"
echo "  PID: ${FFMPEG_PID}"
echo "  Devices: ${DEVICES_USED}"
echo "  Output: ${WAV_FILE}"
echo "  Started: ${START_TIME}"
