import AppKit

enum MenuBarIcon {
    static func image(size: CGFloat = 18) -> NSImage? {
        guard let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "svg"),
              let image = NSImage(contentsOf: url)
        else { return nil }

        image.size = NSSize(width: size, height: size)
        image.isTemplate = true
        return image
    }
}
