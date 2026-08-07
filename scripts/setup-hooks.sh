#!/bin/bash
set -e

SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect CLI location: app bundle, Homebrew, or local install
if [ -f "$SCRIPT_DIR/../MacOS/pester-cli" ]; then
    CLI="$SCRIPT_DIR/../MacOS/pester-cli"
elif [ -f "$HOME/Applications/Pester.app/Contents/MacOS/pester-cli" ]; then
    CLI="$HOME/Applications/Pester.app/Contents/MacOS/pester-cli"
elif [ -f "/Applications/Pester.app/Contents/MacOS/pester-cli" ]; then
    CLI="/Applications/Pester.app/Contents/MacOS/pester-cli"
elif command -v pester-cli &>/dev/null; then
    CLI="$(command -v pester-cli)"
elif [ -f "$HOME/.pester/bin/pester-cli" ]; then
    CLI="$HOME/.pester/bin/pester-cli"
else
    echo "Error: pester-cli not found"
    exit 1
fi

# Resolve to absolute path
CLI="$(cd "$(dirname "$CLI")" && pwd)/$(basename "$CLI")"

# Ensure settings file exists
if [ ! -f "$SETTINGS" ]; then
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{}' > "$SETTINGS"
fi

# Replace Pester's Claude adapter hooks using python3 (ships with macOS)
python3 - "$SETTINGS" "$CLI" <<'PYTHON'
import json, sys

settings_path = sys.argv[1]
cli_path = sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})

def without_pester(entries):
    cleaned = []
    for entry in entries:
        entry_hooks = entry.get("hooks")
        if not isinstance(entry_hooks, list):
            cleaned.append(entry)
            continue
        remaining = [
            hook for hook in entry_hooks
            if "pester-cli" not in hook.get("command", "")
        ]
        if remaining:
            cleaned.append({**entry, "hooks": remaining})
    return cleaned

for event in ["PermissionRequest", "Notification", "PostToolUse", "Stop"]:
    hooks[event] = without_pester(hooks.get(event, []))

hooks["PermissionRequest"] = hooks.get("PermissionRequest", []) + [
    {
        "matcher": "",
        "hooks": [{"type": "command", "command": f"{cli_path} claude set"}]
    }
]

hooks["Notification"] = hooks.get("Notification", []) + [
    {
        "matcher": "^(?!permission_prompt)",
        "hooks": [{"type": "command", "command": f"{cli_path} claude set"}]
    }
]

hooks["PostToolUse"] = hooks.get("PostToolUse", []) + [
    {
        "matcher": "",
        "hooks": [{"type": "command", "command": f"{cli_path} claude clear"}]
    }
]

hooks["Stop"] = hooks.get("Stop", []) + [
    {
        "matcher": "",
        "hooks": [{"type": "command", "command": f"{cli_path} claude clear"}]
    }
]

settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print(f"Hooks added to {settings_path}")
PYTHON
