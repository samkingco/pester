import AppKit
import PesterProtocol
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var notchWindow: NotchWindow!
    private var statusItem: NSStatusItem?
    private var pendingNotifications: [String: PendingNotification] = [:]
    private var lastActivatedBundleId: String?

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
            guard let self else { return }
            self.pendingNotifications.removeAll()
            self.notchWindow.updateNotifications([])
            self.activateTerminal()
        }
    }

    private func setupNotificationObservers() {
        let center = DistributedNotificationCenter.default()

        center.addObserver(
            self,
            selector: #selector(handleNotificationSet(_:)),
            name: PesterProtocol.setNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleNotificationClear(_:)),
            name: PesterProtocol.clearNotification,
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

        lastActivatedBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = MenuBarIcon.image()

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

    @objc private func handleNotificationSet(_ notification: Notification) {
        guard let info = notification.userInfo,
              let id = info[PesterProtocol.Key.id] as? String,
              let adapterId = info[PesterProtocol.Key.adapterId] as? String,
              let adapter = AdapterID(rawValue: adapterId),
              let title = info[PesterProtocol.Key.title] as? String
        else { return }

        let key = notificationKey(adapter: adapter, id: id)
        let summary = info[PesterProtocol.Key.summary] as? String ?? ""
        let isNew = pendingNotifications[key] == nil

        if isNew,
           let soundName = Constants.notificationSound,
           let sound = NSSound(named: NSSound.Name(soundName))?.copy() as? NSSound {
            sound.play()
        }

        // Suppress everything visual when terminal is frontmost — don't even track
        // the notification, so a later `clear` for another session can't cause a stale
        // render from leftover dict entries.
        if isTerminalFrontmost() { return }

        pendingNotifications[key] = PendingNotification(
            id: key,
            adapter: .bundled(adapter),
            title: title,
            summary: summary
        )
        notchWindow.updateNotifications(Array(pendingNotifications.values))
    }

    @objc private func handleNotificationClear(_ notification: Notification) {
        guard let info = notification.userInfo,
              let id = info[PesterProtocol.Key.id] as? String,
              let adapterId = info[PesterProtocol.Key.adapterId] as? String,
              let adapter = AdapterID(rawValue: adapterId)
        else { return }

        pendingNotifications.removeValue(forKey: notificationKey(adapter: adapter, id: id))

        if isTerminalFrontmost() { return }

        notchWindow.updateNotifications(Array(pendingNotifications.values))
    }

    private func notificationKey(adapter: AdapterID, id: String) -> String {
        "\(adapter.rawValue):\(id)"
    }

    private func isTerminalFrontmost() -> Bool {
        // Three independent signals — any positive match suppresses.
        // why: NSWorkspace.frontmostApplication can be stale inside a
        // DistributedNotification handler, and the cached activation id can be
        // unseeded at launch. NSRunningApplication.isActive is the most direct.
        let terminalIsActive = NSRunningApplication
            .runningApplications(withBundleIdentifier: Constants.terminalBundleId)
            .contains { $0.isActive }
        if terminalIsActive { return true }
        if lastActivatedBundleId == Constants.terminalBundleId { return true }
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Constants.terminalBundleId { return true }
        return false
    }

    // MARK: - Workspace

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier,
              bundleId != Bundle.main.bundleIdentifier
        else { return }

        lastActivatedBundleId = bundleId

        if bundleId == Constants.terminalBundleId {
            pendingNotifications.removeAll()
            notchWindow.updateNotifications([])
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
        let samples: [(AdapterID, String, String)] = [
            (.claude, "Bash", "rm -rf node_modules && npm install"),
            (.claude, "Edit", "src/components/Dashboard.tsx"),
            (.claude, "Write", "tests/integration/auth.test.ts"),
            (.pi, "Finished", "Implemented the notification adapter"),
            (.pi, "Finished", "Tests passed"),
        ]

        let (adapter, title, summary) = samples.randomElement()!
        let id = "test-\(UUID().uuidString.prefix(8))"

        DistributedNotificationCenter.default().postNotificationName(
            PesterProtocol.setNotification,
            object: nil,
            userInfo: [
                PesterProtocol.Key.id: id,
                PesterProtocol.Key.adapterId: adapter.rawValue,
                PesterProtocol.Key.title: title,
                PesterProtocol.Key.summary: summary,
            ]
        )
    }

    @objc private func clearAll() {
        pendingNotifications.removeAll()
        notchWindow.updateNotifications([])
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
