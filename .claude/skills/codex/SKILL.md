---
name: codex
description: Run OpenAI Codex for code review, security analysis, or second-opinion on code. Use when user says "codex", "codex review", "second opinion", or wants GPT-based code analysis.
allowed_tools:
  - Bash
  - AskUserQuestion
  - Read
  - Glob
---

# Codex — OpenAI Code Review & Analysis Skill

Use OpenAI Codex CLI to get a second opinion on code via GPT models.

## When to Use

- Code review (bugs, security, logic issues)
- Second opinion on architecture or implementation
- Comparing Claude's analysis with GPT's analysis

## Workflow

### 1. Ask the user what they want to analyze

Use AskUserQuestion to gather:
- **Target**: Which files/directories to review? (default: current directory)
- **Task type**: `review` (code review) or custom prompt

If the user already provided these details, skip this step.

### 2. Execute Codex

IMPORTANT: The current setup uses ChatGPT account login. Do NOT specify `-m` model flag — use the default model.

For **code review**, use the built-in review command:

```bash
codex exec review 2>/dev/null
```

For **custom prompts**, use:

```bash
codex exec \
  --sandbox read-only \
  --ephemeral \
  "<prompt>" 2>/dev/null
```

IMPORTANT:
- Do NOT specify `-m <model>` — ChatGPT login only supports the default model
- Always append `2>/dev/null` to suppress thinking tokens from polluting output
- Always use `--sandbox read-only` for safety (prevents file modifications)
- Always use `--ephemeral` to avoid saving sessions
- Must run inside a git repository directory

### 3. Present Results

- Show the Codex output clearly
- If doing code review, optionally run Claude's own analysis and present a **comparison table**:

| Issue | Codex (GPT) | Claude | Agree? |
|-------|-------------|--------|--------|
| ...   | ...         | ...    | ...    |

## Example Commands

```bash
# Quick code review of current repo
codex exec review 2>/dev/null

# Review specific files
codex exec --sandbox read-only --ephemeral "Review src/auth/ for security vulnerabilities" 2>/dev/null

# Architecture analysis
codex exec --sandbox read-only --ephemeral "Analyze the architecture of this project and suggest improvements" 2>/dev/null
```

## Notes

- If the user later switches to an API key (instead of ChatGPT login), the `-m` flag can be re-enabled with models like `o3`, `o4-mini`, `gpt-4.1`
- Cost is doubled when running both Claude + Codex, so use selectively for high-value tasks
