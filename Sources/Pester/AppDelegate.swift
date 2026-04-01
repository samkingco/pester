import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var notchWindow: NotchWindow!
    private var statusItem: NSStatusItem?
    private var pendingApprovals: [String: PendingApproval] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupNotchWindow()
        setupNotificationObservers()
        setupWorkspaceObserver()
        setupStatusItem()
        registerLoginItem()
    }

    // MARK: - Setup

    private func setupNotchWindow() {
        notchWindow = NotchWindow()
        notchWindow.state.onTap = { [weak self] in
            self?.activateTerminal()
        }
    }

    private func setupNotificationObservers() {
        let center = DistributedNotificationCenter.default()

        center.addObserver(
            self,
            selector: #selector(handleApprovalSet(_:)),
            name: Notification.Name("com.pester.approval.set"),
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleApprovalClear(_:)),
            name: Notification.Name("com.pester.approval.clear"),
            object: nil
        )
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
            NSSound(named: NSSound.Name(name))?.play()
        }
    }

    private func registerLoginItem() {
        try? SMAppService.mainApp.register()
    }

    // MARK: - Distributed Notifications

    @objc private func handleApprovalSet(_ notification: Notification) {
        guard let info = notification.userInfo,
              let sessionId = info["session_id"] as? String,
              let toolName = info["tool_name"] as? String
        else { return }

        let summary = info["summary"] as? String ?? ""
        let isNew = pendingApprovals[sessionId] == nil
        pendingApprovals[sessionId] = PendingApproval(
            id: sessionId,
            toolName: toolName,
            summary: summary
        )

        // Don't show if terminal is focused
        if isTerminalActive() { return }

        notchWindow.updateApprovals(Array(pendingApprovals.values))

        if isNew,
           let soundName = Constants.notificationSound,
           let sound = NSSound(named: NSSound.Name(soundName))?.copy() as? NSSound {
            sound.play()
        }
    }

    @objc private func handleApprovalClear(_ notification: Notification) {
        guard let info = notification.userInfo,
              let sessionId = info["session_id"] as? String
        else { return }

        pendingApprovals.removeValue(forKey: sessionId)
        notchWindow.updateApprovals(Array(pendingApprovals.values))
    }

    // MARK: - Workspace

    private func isTerminalActive() -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Constants.terminalBundleId
    }

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier
        else { return }

        if bundleId == Constants.terminalBundleId {
            pendingApprovals.removeAll()
            notchWindow.updateApprovals([])
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

        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.pester.approval.set"),
            object: nil,
            userInfo: [
                "session_id": sessionId,
                "tool_name": tool,
                "summary": summary,
            ]
        )
    }

    @objc private func clearAll() {
        pendingApprovals.removeAll()
        notchWindow.updateApprovals([])
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
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
