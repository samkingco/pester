#!/bin/bash
set -e

SETTINGS="$HOME/.claude/settings.json"
CLI="$HOME/.pester/bin/pester-cli"

# Ensure settings file exists
if [ ! -f "$SETTINGS" ]; then
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{}' > "$SETTINGS"
fi

# Check if hooks already configured
if grep -q "pester-cli" "$SETTINGS" 2>/dev/null; then
    echo "Hooks already configured in $SETTINGS"
    exit 0
fi

# Merge hooks into existing settings using python3 (ships with macOS)
python3 - "$SETTINGS" "$CLI" <<'PYTHON'
import json, sys

settings_path = sys.argv[1]
cli_path = sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})

hooks["Notification"] = hooks.get("Notification", []) + [
    {
        "matcher": "permission_prompt",
        "hooks": [{"type": "command", "command": f"{cli_path} set"}]
    }
]

hooks["PostToolUse"] = hooks.get("PostToolUse", []) + [
    {
        "matcher": "",
        "hooks": [{"type": "command", "command": f"{cli_path} clear"}]
    }
]

hooks["Stop"] = hooks.get("Stop", []) + [
    {
        "matcher": "",
        "hooks": [{"type": "command", "command": f"{cli_path} clear"}]
    }
]

settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print(f"Hooks added to {settings_path}")
PYTHON
