---
name: meeting-stop
description: Stop a meeting recording, transcribe with speaker diarization (Deepgram), and generate structured meeting notes.
allowed-tools: Bash(kill *), Bash(bash *), Bash(curl *), Bash(python3 *), Bash(cat *), Bash(mkdir *), Bash(mv *), Bash(cp *), Bash(ls *), Bash(wc *), Bash(du *), Read, Write
---

# Meeting Stop

Stop the current meeting recording, transcribe it with speaker diarization, and generate structured meeting notes.

## Steps

### 1. Stop the recording
```bash
bash ~/.claude/skills/meeting-stop/scripts/stop-recording.sh
```
If this fails (no recording in progress), inform the user and stop.

### 2. Read meeting metadata
```bash
cat /tmp/claude_meeting.meta
```

### 3. Transcribe the audio
Run the transcription script. Uses Deepgram (with speaker diarization) as primary, Groq Whisper as fallback:
```bash
bash ~/.claude/skills/meeting-stop/scripts/transcribe.sh
```
If this fails (missing API key, network error), inform the user but still save the recording.

### 4. Read the transcript
Read the transcript file at `/tmp/claude_meeting_transcript.txt`.

### 5. Create output directory
```bash
MEETING_DIR=~/meetings/$(date +%Y-%m-%d_%H%M%S)
mkdir -p "$MEETING_DIR"
```

### 6. Save the recording and transcript
```bash
cp /tmp/claude_meeting.wav "$MEETING_DIR/recording.wav"
cp /tmp/claude_meeting_transcript.txt "$MEETING_DIR/transcript.txt"
```

### 7. Generate meeting notes
Based on the transcript content, generate a structured meeting note in the **same language as the transcript** (Korean if the meeting was in Korean, English if in English, mixed if both were used).

Use this format and write it to `$MEETING_DIR/meeting-note.md`:

```markdown
# Meeting Note — [DATE from metadata]

## Participants
- Speaker 0: [Role/name if identifiable from context, otherwise "Speaker 0"]
- Speaker 1: [Role/name if identifiable from context, otherwise "Speaker 1"]

## Summary
[1-3 sentence summary in the meeting's primary language]

## Key Discussion Points
- [Point 1]
- [Point 2]
- ...

## Action Items
- [ ] [Speaker/Owner if mentioned] — [Task description]
- ...

## Decisions Made
- [Decision 1]
- ...

## Full Transcript
[Paste the full timestamped transcript with speaker labels here]
```

If the transcript is too short or empty, note that in the summary and skip the detailed sections.
If only one speaker is present, omit the Participants section.

### 8. Clean up temp files
```bash
rm -f /tmp/claude_meeting.pid /tmp/claude_meeting.meta
```
Keep `/tmp/claude_meeting.wav` and `/tmp/claude_meeting_transcript.txt` as backup until the next recording.

### 9. Report to user
- Confirm recording stopped
- Show meeting duration (from metadata start time to now)
- Show output directory path
- Show brief summary of what was discussed (from the generated notes)
- If any step failed, clearly indicate what succeeded and what didn't
