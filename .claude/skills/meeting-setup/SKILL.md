---
name: meeting-setup
description: Check and guide installation of meeting recording dependencies (ffmpeg, BlackHole, Deepgram, Groq).
allowed-tools: Bash(which *), Bash(brew *), Bash(ffmpeg *), Bash(echo *), Bash(cat *), Bash(source *)
---

# Meeting Setup

Check and guide the user through installing dependencies for meeting recording and transcription.

## Steps

### 1. Check ffmpeg
```bash
which ffmpeg && ffmpeg -version 2>&1 | head -1 || echo "NOT_INSTALLED"
```

If not installed, tell the user:
```
brew install ffmpeg
```

### 2. Check BlackHole 2ch (for system audio capture)
```bash
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -i blackhole || echo "NOT_FOUND"
```

If not found, tell the user:
```
brew install blackhole-2ch
```

Then explain the audio routing setup:
1. Open **Audio MIDI Setup** (Spotlight → "Audio MIDI Setup")
2. Click **+** at bottom-left → **Create Multi-Output Device**
3. Check both **BlackHole 2ch** and your regular output (speakers/headphones)
4. Right-click the Multi-Output Device → **Use This Device For Sound Output**

This routes system audio to both your speakers AND BlackHole for recording.

**Important**: BlackHole is optional. Without it, only microphone audio is captured (fine for in-person meetings, but online meeting audio from the other party won't be recorded).

### 3. Check API keys

**DEEPGRAM_API_KEY** (primary — supports speaker diarization):
```bash
source ~/.zshrc 2>/dev/null; echo "DEEPGRAM_API_KEY is ${DEEPGRAM_API_KEY:+set}${DEEPGRAM_API_KEY:-NOT SET}"
```

If not set, tell the user:
1. Go to https://console.deepgram.com (free $200 credit, no expiration)
2. Create an API key
3. Add to shell config:
```bash
echo 'export DEEPGRAM_API_KEY="your-key-here"' >> ~/.zshrc
```

**GROQ_API_KEY** (fallback — no speaker diarization, but faster):
```bash
source ~/.zshrc 2>/dev/null; echo "GROQ_API_KEY is ${GROQ_API_KEY:+set}${GROQ_API_KEY:-NOT SET}"
```

If not set, tell the user:
1. Go to https://console.groq.com/keys (free tier: 8hr/day)
2. Create an API key
3. Add to shell config:
```bash
echo 'export GROQ_API_KEY="your-key-here"' >> ~/.zshrc
```

At least one API key must be set. Deepgram is recommended for speaker diarization.

### 4. Verify audio devices
```bash
ffmpeg -f avfoundation -list_devices true -i "" 2>&1
```

Show the user the available audio devices so they can verify their setup.

### 5. Summary
Report the status of each dependency:
- ffmpeg: installed / not installed
- BlackHole 2ch: detected / not detected (optional)
- DEEPGRAM_API_KEY: set / not set (primary, speaker diarization)
- GROQ_API_KEY: set / not set (fallback)

If everything is ready, tell the user they can start recording with `/meeting-start`.
