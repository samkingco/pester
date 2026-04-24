# Changelog

## [0.3.2] — 2026-04-24

### Fixes
- Suppress the notch reliably when the terminal is frontmost. The `clear` handler could re-render the notch from pending-approval state that had accumulated during suppressed `set`s (c088d5f)
- Strengthen "terminal frontmost" detection with three independent signals so individual lies inside DistributedNotification handlers don't slip through (c088d5f)
- Tap now always clears and hides the notch before activating the terminal, so clicking while the terminal is already frontmost dismisses instead of no-op'ing (c088d5f)
- Sound plays independently of visual suppression (c088d5f)

## [0.3.1] — 2026-03-31

### Fixes
- Replace file-based IPC with DistributedNotificationCenter for instant CLI-to-app communication (3862b07)
- Fix notch window capturing clicks in transparent areas outside the notch shape (3862b07)
- Fix notch reappearing on app switch due to stale file state races (3862b07)
- Fix missing state case in updateApprovals when new approvals arrive during dismiss animation (3862b07)

### Other
- Fix README icon path (67f2eee)
- Remove FileWatcher and pending directory code (3862b07)

## [0.3.0] — 2026-03-28

### Fixes
- Fix app icon with macOS superellipse shape (b9a18d5)

### Other
- Switch to Homebrew Cask distribution (b9a18d5)

## [0.2.0] — 2026-03-28

### Features
- Menu bar status item with sound preferences (d0866a9)
- Richer notifications with tool name and summary (d0866a9)

## [0.1.0] — 2026-03-28

Initial release. Notch-based notification for Claude Code permission prompts.
