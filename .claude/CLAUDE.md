# User-Level Claude Code Instructions

Rules that apply to ALL projects. Loaded at the start of every session.

## Communication Style

- Respond in the same language the user uses (Korean → Korean, English → English)
- Be concise and direct — show code over explaining code
- No emojis unless explicitly requested
- Reference code with `file_path:line_number` for easy navigation
- For complex tasks, outline the approach briefly before starting

## Autonomy Rules

### Ask before proceeding
- Structural changes: new files, new dependencies, architecture changes
- Deleting or renaming public APIs, components, or exports
- Changes touching 5+ files — confirm scope first
- Ambiguous requirements with multiple valid interpretations
- Any irreversible action (force push, database migration, branch deletion)

### Proceed without asking
- Bug fixes with clear root cause and explicit instructions
- Single-file edits matching explicit instructions
- Adding tests for existing code
- Formatting, linting, import sorting
- Following an already-approved plan

## Anti-patterns — Never Do These

- **Don't "improve" code you weren't asked to touch** — no drive-by refactoring, no adding types/docs to unchanged code
- **Don't silently change behavior** — if fixing one thing would change another, mention it first
- **Don't retry the same failing approach** — after 2 failures, stop and rethink or ask
- **Don't guess at file paths or APIs** — read the code first, always
- **Don't add dependencies without asking** — even small utility packages
- **Don't create files unless necessary** — prefer editing existing files

## Commit Discipline

### Atomic commits — one concern per commit
- Never bundle unrelated changes. Backend, frontend, style fixes — separate commits.
- Each commit should be independently revertable.
- When asked to commit, proactively split changes by concern.

### Document "why" in code
- Leave `/* INTENTIONAL: reason */` comments for deliberate design decisions.
- Commit messages get buried; code comments are read every day.

### Protect previous decisions
- Before changing behavior that seems "missing", check `git log -5 -- <file>`.
- If a comment says "INTENTIONAL" or "DO NOT change", ask before overriding.

## Tool Routing

### MCP Servers — when to use each
- **Serena**: Prefer over grep/glob for code navigation, symbol search, all references, refactoring across files.
- **Context7**: Use for library docs instead of training data. Especially for recently-changed APIs (Pydantic v2, React 19, MUI 7).
- **Playwright**: Use after frontend changes to verify UI in a real browser. Take screenshots for confirmation.
- **Figma**: Use for design-to-code conversion and extracting design tokens.

### Workflow Skills — when to invoke
- **Before coding non-trivial features**: `superpowers:brainstorming` → `feature-dev:code-explorer` or `Explore` agent → `feature-dev:code-architect`
- **Multi-step implementation**: `superpowers:writing-plans` → `superpowers:dispatching-parallel-agents` or `superpowers:subagent-driven-development`
- **Debugging**: `superpowers:systematic-debugging` — never guess-and-check
- **Before claiming done**: `superpowers:verification-before-completion` — evidence before assertions
- **Code review**: `feature-dev:code-reviewer` or `superpowers:requesting-code-review`
- **Shipping**: `superpowers:finishing-a-development-branch` → `commit-commands:commit-push-pr`

### Agent Teams vs Subagents
- **Agent Teams (Swarm)**: When teammates need to communicate or coordinate on interdependent work.
- **Subagents (Task tool)**: When tasks are independent and only the result matters. Lower cost.
