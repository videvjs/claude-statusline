#!/usr/bin/env bash
set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_NAME="statusline-command.sh"
REPO_RAW="https://raw.githubusercontent.com/videv/claude-statusline/main"

echo "→ Installing claude-statusline..."

# 1. Create ~/.claude if needed
mkdir -p "$CLAUDE_DIR"

# 2. Download the script
curl -fsSL "$REPO_RAW/$SCRIPT_NAME" -o "$CLAUDE_DIR/$SCRIPT_NAME"
chmod +x "$CLAUDE_DIR/$SCRIPT_NAME"
echo "✓ Script → $CLAUDE_DIR/$SCRIPT_NAME"

# 3. Patch ~/.claude/settings.json
SETTINGS="$CLAUDE_DIR/settings.json"
ABSOLUTE_COMMAND="bash $CLAUDE_DIR/$SCRIPT_NAME"

python3 - <<PYEOF
import json, os, sys

settings_path = "$SETTINGS"
command = "$ABSOLUTE_COMMAND"

# Load or init
if os.path.exists(settings_path):
    with open(settings_path, 'r') as f:
        try:
            settings = json.load(f)
        except json.JSONDecodeError:
            print("✗ settings.json is invalid JSON — fix it manually then re-run.", file=sys.stderr)
            sys.exit(1)
else:
    settings = {}

# Backup
import shutil
if os.path.exists(settings_path):
    shutil.copy2(settings_path, settings_path + ".bak")

# Inject
settings['statusLine'] = {
    'type': 'command',
    'command': command
}

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print("✓ settings.json updated (backup → settings.json.bak)")
PYEOF

echo ""
echo "✅ Done! Restart Claude Code to see your status line."
