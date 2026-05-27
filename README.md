# claude-statusline

A custom status line for [Claude Code](https://claude.ai/code) showing folder, git branch, model, context usage, and rate limits — all with color-coded progress bars.

![status line preview](https://i.imgur.com/placeholder.png)

## What it shows

`/project-name | (main) | claude-opus-4-6 | ctx [████████░░] 78% | 5h [███░░░░░░░] 28% Reset in 1h42m`

| Segment | Description |
|---|---|
| `/folder` | Current project directory |
| `(branch)` | Git branch or short commit hash |
| Model | Active model name + effort level if set |
| `ctx` | Context window usage (blue → yellow → red) |
| `5h` | 5-hour rate limit with countdown to reset |
| `7d` | 7-day rate limit (only shown above 30%) |

## Install

**Requirements:** `bash`, `python3`, `curl` (standard on macOS/Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/videv/claude-statusline/main/install.sh | bash
```

That's it. Restart Claude Code.

## What the installer does

1. Downloads `statusline-command.sh` to `~/.claude/`
2. Patches `~/.claude/settings.json` to enable the status line
3. Creates a `settings.json.bak` backup before touching anything

## Uninstall

Remove the `statusLine` block from `~/.claude/settings.json` and delete `~/.claude/statusline-command.sh`.

## Requirements

- Claude Code
- `bash` + `python3` (already on macOS, standard on most Linux)
- A terminal that supports 24-bit color (most modern terminals do)
