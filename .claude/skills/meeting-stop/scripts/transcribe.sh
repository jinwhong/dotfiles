#!/bin/bash
set -euo pipefail

# Auto-load API keys from shell config if not already set
if [ -z "${DEEPGRAM_API_KEY:-}" ] && [ -f ~/.zshrc ]; then
    DEEPGRAM_API_KEY=$(sed -n 's/^export DEEPGRAM_API_KEY="\(.*\)"/\1/p' ~/.zshrc 2>/dev/null | tail -1 || true)
    export DEEPGRAM_API_KEY
fi
if [ -z "${GROQ_API_KEY:-}" ] && [ -f ~/.zshrc ]; then
    GROQ_API_KEY=$(sed -n 's/^export GROQ_API_KEY="\(.*\)"/\1/p' ~/.zshrc 2>/dev/null | tail -1 || true)
    export GROQ_API_KEY
fi

WAV_FILE="/tmp/claude_meeting.wav"
TRANSCRIPT_FILE="/tmp/claude_meeting_transcript.txt"

if [ ! -f "$WAV_FILE" ]; then
    echo "ERROR: Recording file not found at $WAV_FILE"
    exit 1
fi

FILE_SIZE_BYTES=$(stat -f%z "$WAV_FILE" 2>/dev/null || stat -c%s "$WAV_FILE" 2>/dev/null)
FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))

echo "Transcribing audio file..."
echo "  File: $WAV_FILE"
echo "  Size: ${FILE_SIZE_MB}MB"

# ---------- Deepgram (primary): supports speaker diarization ----------
if [ -n "${DEEPGRAM_API_KEY:-}" ]; then
    echo "  Using Deepgram API (with speaker diarization)..."

    RESPONSE=$(curl -s -X POST \
        "https://api.deepgram.com/v1/listen?model=nova-3&smart_format=true&diarize=true&utterances=true&detect_language=true" \
        -H "Authorization: Token ${DEEPGRAM_API_KEY}" \
        -H "Content-Type: audio/wav" \
        --data-binary "@${WAV_FILE}")

    # Check for errors
    if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'results' in d else 1)" 2>/dev/null; then
        echo "$RESPONSE" | python3 -c "
import sys, json

data = json.load(sys.stdin)
utterances = data.get('results', {}).get('utterances', [])

if utterances:
    for utt in utterances:
        speaker = utt.get('speaker', 0)
        start = utt.get('start', 0)
        text = utt.get('transcript', '').strip()
        if text:
            hours, rem = divmod(int(start), 3600)
            minutes, seconds = divmod(rem, 60)
            print(f'[{hours:02d}:{minutes:02d}:{seconds:02d}] Speaker {speaker}: {text}')
else:
    # Fallback: use words with speaker labels
    words = data.get('results', {}).get('channels', [{}])[0].get('alternatives', [{}])[0].get('words', [])
    if not words:
        transcript = data.get('results', {}).get('channels', [{}])[0].get('alternatives', [{}])[0].get('transcript', '')
        if transcript:
            print(f'[00:00:00] {transcript}')
    else:
        current_speaker = None
        current_text = []
        current_start = 0
        for w in words:
            speaker = w.get('speaker', 0)
            if speaker != current_speaker:
                if current_text and current_speaker is not None:
                    hours, rem = divmod(int(current_start), 3600)
                    minutes, seconds = divmod(rem, 60)
                    print(f'[{hours:02d}:{minutes:02d}:{seconds:02d}] Speaker {current_speaker}: {\" \".join(current_text)}')
                current_speaker = speaker
                current_text = [w.get('punctuated_word', w.get('word', ''))]
                current_start = w.get('start', 0)
            else:
                current_text.append(w.get('punctuated_word', w.get('word', '')))
        if current_text and current_speaker is not None:
            hours, rem = divmod(int(current_start), 3600)
            minutes, seconds = divmod(rem, 60)
            print(f'[{hours:02d}:{minutes:02d}:{seconds:02d}] Speaker {current_speaker}: {\" \".join(current_text)}')
" > "$TRANSCRIPT_FILE"
    else
        ERROR=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('err_msg', d.get('error', 'Unknown error')))" 2>/dev/null || echo "$RESPONSE")
        echo "  WARNING: Deepgram failed: $ERROR"
        echo "  Falling back to Groq Whisper..."
        DEEPGRAM_API_KEY=""  # Force fallback
    fi
fi

# ---------- Groq Whisper (fallback): no speaker diarization ----------
if [ ! -s "$TRANSCRIPT_FILE" ] && [ -z "${DEEPGRAM_API_KEY:-}" ]; then
    if [ -z "${GROQ_API_KEY:-}" ]; then
        echo "ERROR: No API keys available. Set DEEPGRAM_API_KEY or GROQ_API_KEY."
        echo "  Deepgram: https://console.deepgram.com"
        echo "  Groq: https://console.groq.com/keys"
        exit 1
    fi

    echo "  Using Groq Whisper API (no speaker diarization)..."

    MAX_SIZE_BYTES=$((25 * 1024 * 1024))

    if [ "$FILE_SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
        echo "  File exceeds 25MB limit. Splitting into chunks..."

        CHUNK_DIR="/tmp/claude_meeting_chunks"
        rm -rf "$CHUNK_DIR"
        mkdir -p "$CHUNK_DIR"

        CHUNK_DURATION=600

        if command -v ffprobe &> /dev/null; then
            TOTAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$WAV_FILE" 2>/dev/null | cut -d. -f1)
        else
            TOTAL_DURATION=$((FILE_SIZE_BYTES / 32000))
        fi

        NUM_CHUNKS=$(( (TOTAL_DURATION + CHUNK_DURATION - 1) / CHUNK_DURATION ))
        echo "  Total duration: ~${TOTAL_DURATION}s, splitting into ${NUM_CHUNKS} chunks"

        > "$TRANSCRIPT_FILE"

        for i in $(seq 0 $((NUM_CHUNKS - 1))); do
            START=$((i * CHUNK_DURATION))
            CHUNK_FILE="${CHUNK_DIR}/chunk_${i}.wav"

            echo "  Processing chunk $((i + 1))/${NUM_CHUNKS} (starting at ${START}s)..."

            ffmpeg -i "$WAV_FILE" -ss "$START" -t "$CHUNK_DURATION" \
                -acodec pcm_s16le -ar 16000 -ac 1 \
                -y "$CHUNK_FILE" 2>/dev/null

            RESPONSE=$(curl -s -X POST "https://api.groq.com/openai/v1/audio/transcriptions" \
                -H "Authorization: Bearer ${GROQ_API_KEY}" \
                -F "file=@${CHUNK_FILE}" \
                -F "model=whisper-large-v3" \
                -F "response_format=verbose_json" \
                -F "timestamp_granularities[]=segment")

            if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'text' in d else 1)" 2>/dev/null; then
                echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
offset = ${START}
if 'segments' in data:
    for seg in data['segments']:
        start = seg.get('start', 0) + offset
        text = seg.get('text', '').strip()
        if text:
            hours, rem = divmod(int(start), 3600)
            minutes, seconds = divmod(rem, 60)
            print(f'[{hours:02d}:{minutes:02d}:{seconds:02d}] {text}')
else:
    text = data.get('text', '').strip()
    if text:
        hours, rem = divmod(offset, 3600)
        minutes, seconds = divmod(rem, 60)
        print(f'[{hours:02d}:{minutes:02d}:{seconds:02d}] {text}')
" >> "$TRANSCRIPT_FILE"
            else
                ERROR=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('message','Unknown error'))" 2>/dev/null || echo "Unknown error")
                echo "  WARNING: Chunk $((i + 1)) transcription failed: $ERROR"
            fi
        done

        rm -rf "$CHUNK_DIR"
    else
        RESPONSE=$(curl -s -X POST "https://api.groq.com/openai/v1/audio/transcriptions" \
            -H "Authorization: Bearer ${GROQ_API_KEY}" \
            -F "file=@${WAV_FILE}" \
            -F "model=whisper-large-v3" \
            -F "response_format=verbose_json" \
            -F "timestamp_granularities[]=segment")

        if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'text' in d else 1)" 2>/dev/null; then
            echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'segments' in data:
    for seg in data['segments']:
        start = seg.get('start', 0)
        text = seg.get('text', '').strip()
        if text:
            hours, rem = divmod(int(start), 3600)
            minutes, seconds = divmod(rem, 60)
            print(f'[{hours:02d}:{minutes:02d}:{seconds:02d}] {text}')
else:
    text = data.get('text', '').strip()
    if text:
        print(f'[00:00:00] {text}')
" > "$TRANSCRIPT_FILE"
        else
            ERROR=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('message','Unknown error'))" 2>/dev/null || echo "$RESPONSE")
            echo "ERROR: Transcription failed: $ERROR"
            exit 1
        fi
    fi
fi

# Report results
if [ -f "$TRANSCRIPT_FILE" ]; then
    LINE_COUNT=$(wc -l < "$TRANSCRIPT_FILE" | tr -d ' ')
    CHAR_COUNT=$(wc -c < "$TRANSCRIPT_FILE" | tr -d ' ')
    echo ""
    echo "Transcription complete"
    echo "  Output: $TRANSCRIPT_FILE"
    echo "  Lines: $LINE_COUNT"
    echo "  Characters: $CHAR_COUNT"
else
    echo "ERROR: Transcript file was not created"
    exit 1
fi
