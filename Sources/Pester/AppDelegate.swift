import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var notchWindow: NotchWindow!
    private var fileWatcher: FileWatcher?
    private var statusItem: NSStatusItem?
    private var currentApprovals: [PendingApproval] = []
    private var terminalIsActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensurePendingDirectory()
        setupNotchWindow()
        setupFileWatcher()
        setupWorkspaceObserver()
        setupStatusItem()
        registerLoginItem()
        refreshPendingApprovals()
    }

    // MARK: - Setup

    private func ensurePendingDirectory() {
        try? FileManager.default.createDirectory(
            at: Constants.pendingDirectory,
            withIntermediateDirectories: true
        )
    }

    private func setupNotchWindow() {
        notchWindow = NotchWindow()
        notchWindow.state.onTap = { [weak self] in
            self?.activateTerminal()
        }
    }

    private func setupFileWatcher() {
        fileWatcher = FileWatcher(directory: Constants.pendingDirectory) { [weak self] in
            self?.refreshPendingApprovals()
        }
    }

    private func setupWorkspaceObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = ClaudeIcon.menuBarImage()

        let menu = NSMenu()
        menu.delegate = self

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let versionItem = NSMenuItem(title: "Pester v\(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false

        menu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: ""))
        menu.addItem(buildSoundMenu())
        menu.addItem(NSMenuItem(title: "Pester Tester", action: #selector(triggerTest), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(versionItem)
        menu.addItem(NSMenuItem(title: "GitHub", action: #selector(openGitHub), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Uninstall…", action: #selector(confirmUninstall), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Pester", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    private func buildSoundMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Sound", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let offItem = NSMenuItem(title: "Off", action: #selector(selectSound(_:)), keyEquivalent: "")
        offItem.tag = -1
        submenu.addItem(offItem)
        submenu.addItem(.separator())

        for (i, name) in Constants.availableSounds.enumerated() {
            let soundItem = NSMenuItem(title: name, action: #selector(selectSound(_:)), keyEquivalent: "")
            soundItem.tag = i
            submenu.addItem(soundItem)
        }

        item.submenu = submenu
        return item
    }

    @objc private func selectSound(_ sender: NSMenuItem) {
        if sender.tag == -1 {
            Constants.notificationSound = nil
        } else {
            let name = Constants.availableSounds[sender.tag]
            Constants.notificationSound = name
            // Preview the sound
            NSSound(named: NSSound.Name(name))?.play()
        }
    }

    private func registerLoginItem() {
        try? SMAppService.mainApp.register()
    }

    // MARK: - State

    private func refreshPendingApprovals() {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: Constants.pendingDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }

        let approvals = urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? PendingApproval(from: $0) }

        let oldIds = Set(currentApprovals.map(\.id))
        let newIds = Set(approvals.map(\.id))
        let hasNewApprovals = !newIds.subtracting(oldIds).isEmpty

        currentApprovals = approvals

        // Don't show if terminal is already focused
        if terminalIsActive && !approvals.isEmpty { return }

        notchWindow.updateApprovals(approvals)

        if hasNewApprovals && !approvals.isEmpty,
           let soundName = Constants.notificationSound,
           let sound = NSSound(named: NSSound.Name(soundName))?.copy() as? NSSound {
            sound.play()
        }
    }

    // MARK: - Workspace

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier
        else { return }

        if bundleId == Constants.terminalBundleId {
            terminalIsActive = true
            currentApprovals = []
            clearAllPendingFiles()
            notchWindow.updateApprovals([])
        } else {
            terminalIsActive = false
            if !currentApprovals.isEmpty {
                refreshPendingApprovals()
            }
        }
    }

    // MARK: - Actions

    private func activateTerminal() {
        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: Constants.terminalBundleId
        ).first else { return }

        app.activate()
    }

    @objc private func triggerTest() {
        let tools: [(String, String)] = [
            ("Bash", "rm -rf node_modules && npm install"),
            ("Bash", "docker compose up -d --build"),
            ("Edit", "src/components/Dashboard.tsx"),
            ("Write", "tests/integration/auth.test.ts"),
            ("Bash", "git push origin feature/notch-ui"),
            ("Edit", "Package.swift"),
            ("Bash", "swift build -c release"),
            ("Write", "Sources/Pester/NotchWindow.swift"),
            ("Bash", "curl -X POST https://api.example.com/deploy"),
            ("Edit", "config/production.yml"),
        ]

        let (tool, summary) = tools.randomElement()!
        let sessionId = "test-\(UUID().uuidString.prefix(8))"

        let json: [String: Any] = [
            "session_id": sessionId,
            "tool_name": tool,
            "summary": summary,
        ]

        if let data = try? JSONSerialization.data(withJSONObject: json) {
            let file = Constants.pendingDirectory.appendingPathComponent("\(sessionId).json")
            try? data.write(to: file)
        }
    }

    @objc private func clearAll() {
        clearAllPendingFiles()
    }

    private func clearAllPendingFiles() {
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(
            at: Constants.pendingDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) {
            for file in files { try? fm.removeItem(at: file) }
        }
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Update sound submenu checkmarks
        guard let soundItem = menu.items.first(where: { $0.title == "Sound" }),
              let submenu = soundItem.submenu
        else { return }

        let current = Constants.notificationSound

        for item in submenu.items {
            if item.tag == -1 {
                item.state = current == nil ? .on : .off
            } else if item.tag < Constants.availableSounds.count {
                item.state = Constants.availableSounds[item.tag] == current ? .on : .off
            }
        }
    }

    @objc private func confirmUninstall() {
        let alert = NSAlert()
        alert.messageText = "Uninstall Pester?"
        alert.informativeText = "This will remove the app, CLI, Claude Code hooks, and all Pester data."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            uninstall()
        }
    }

    private func uninstall() {
        let fm = FileManager.default

        // Remove hooks from Claude Code settings
        let settingsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        if let data = try? Data(contentsOf: settingsPath),
           var settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           var hooks = settings["hooks"] as? [String: [[String: Any]]] {
            for (key, entries) in hooks {
                hooks[key] = entries.filter { entry in
                    guard let hookList = entry["hooks"] as? [[String: Any]] else { return true }
                    return !hookList.contains { ($0["command"] as? String)?.contains("pester-cli") == true }
                }
            }
            settings["hooks"] = hooks
            if let updated = try? JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted) {
                try? updated.write(to: settingsPath)
            }
        }

        // Remove ~/.pester
        let pesterDir = fm.homeDirectoryForCurrentUser.appendingPathComponent(".pester")
        try? fm.removeItem(at: pesterDir)

        // Remove login item
        try? SMAppService.mainApp.unregister()

        // Remove the app bundle
        let appPath = fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications/Pester.app")
        try? fm.removeItem(at: appPath)

        NSApp.terminate(nil)
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/samkingco/pester")!)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
