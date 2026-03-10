---
name: meeting-start
description: Start recording a meeting using ffmpeg. Captures system audio (via BlackHole) and/or microphone.
allowed-tools: Bash(ffmpeg *), Bash(bash *), Bash(ps *), Bash(cat *), Bash(mkdir *)
disable-model-invocation: true
---

# Meeting Start

Start recording a meeting. This skill captures audio and saves it for later transcription.

## Steps

1. **Check dependencies**: Verify ffmpeg is installed. If not, tell the user to run `/meeting-setup`.

2. **Check for existing recording**: If `/tmp/claude_meeting.pid` exists and the process is still running, inform the user a recording is already in progress and stop.

3. **Run the recording script**:
```bash
bash ~/.claude/skills/meeting-start/scripts/start-recording.sh
```

4. **Verify recording started**: Check that the PID file was created and the process is running:
```bash
cat /tmp/claude_meeting.pid && ps -p $(cat /tmp/claude_meeting.pid) > /dev/null 2>&1 && echo "Recording is running" || echo "ERROR: Recording failed to start"
```

5. **Read metadata and confirm to user**:
```bash
cat /tmp/claude_meeting.meta
```

Report to the user:
- Recording has started
- Which audio devices are being captured
- Remind them to run `/meeting-stop` when the meeting ends
