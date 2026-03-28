import AppKit

enum Constants {
    static let terminalBundleId = "com.mitchellh.ghostty"

    static let availableSounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass",
        "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi",
        "Submarine", "Tink",
    ]

    private static var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".pester/config.json")
    }

    // nil = sound off
    static var notificationSound: String? {
        get {
            guard let data = try? Data(contentsOf: configURL),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return "Glass" }
            if let sound = json["sound"] as? String { return sound }
            if json["sound"] is NSNull { return nil }
            return "Glass"
        }
        set {
            var json: [String: Any] = [:]
            if let data = try? Data(contentsOf: configURL),
               let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                json = existing
            }
            json["sound"] = newValue as Any? ?? NSNull()
            if let data = try? JSONSerialization.data(withJSONObject: json) {
                try? data.write(to: configURL)
            }
        }
    }

    static let expandedWidth: CGFloat = 300
    static let rowHeight: CGFloat = 28
    static let countHeaderHeight: CGFloat = 28
    static let bottomPadding: CGFloat = 12

    static var pendingDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".pester/pending")
    }

    // Dynamic notch metrics from the actual display
    static var notchWidth: CGFloat {
        guard let screen = NSScreen.main,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea
        else { return 200 }
        return screen.frame.width - left.width - right.width + 4
    }

    static var notchHeight: CGFloat {
        guard let screen = NSScreen.main else { return 37 }
        return screen.frame.maxY - screen.visibleFrame.maxY
    }
}
