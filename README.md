<p align="center">
  <img src="Icon/AppIcon-macOS-Default-1024x1024@1x.png" width="128" />
</p>

<p align="center">
  <strong>Pester</strong>, a macOS notch app that pesters you when Claude Code needs approval.
</p>

---

Pester sits behind your MacBook's notch and expands a Dynamic Island-style notification when Claude Code is waiting for permission. Click it to jump to your terminal.

## Install

### Homebrew

```
brew install samkingco/tap/pester
```

### From source

```
git clone https://github.com/samkingco/pester.git
cd pester
make install
```

This builds the app, installs it to `~/Applications/Pester.app`, and configures the Claude Code hooks automatically.

## How it works

```
Claude Code needs approval
  → hook fires
  → pester-cli posts a distributed notification
  → Pester receives it instantly, expands from the notch
  → you click it → terminal focuses

Claude Code continues
  → hook fires
  → pester-cli posts a clear notification
  → notch collapses
```

Communication between `pester-cli` and the app uses macOS `DistributedNotificationCenter` — no files, no polling, instant delivery.

Detection uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks). Hooks are added to `~/.claude/settings.json` on install:

- `PermissionRequest` → `pester-cli set`
- `Notification` → `pester-cli set`
- `PostToolUse` → `pester-cli clear`
- `Stop` → `pester-cli clear`

## Config

Click the menu bar icon to access:

- **Sound** — pick from macOS system sounds or turn off
- **Test Notification** — trigger a fake notification to preview
- **Clear All** — dismiss all pending notifications

Sound preference is saved to `~/.pester/config.json`.

## Terminal

Defaults to [Ghostty](https://ghostty.org). To change, edit `terminalBundleId` in `Sources/Pester/Constants.swift` and rebuild.

## Requirements

- macOS 14+
- MacBook with notch
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## Uninstall

```
make uninstall
```

Remove the hooks from `~/.claude/settings.json` manually, and optionally `rm -rf ~/.pester`.
