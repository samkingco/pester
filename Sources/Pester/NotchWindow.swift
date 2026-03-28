import AppKit
import SwiftUI

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class NotchWindow {
    private let panel: NotchPanel
    let state = NotchState()
    private var isVisible = false

    init() {
        panel = NotchPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.isMovable = false
        panel.level = .mainMenu + 3
        panel.hasShadow = false
        panel.collectionBehavior = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.hidesOnDeactivate = false

        let content = NotchContentView(state: state)
        let hosting = NSHostingView(rootView: content)
        panel.contentView = hosting

        positionWindow()
    }

    func updateApprovals(_ approvals: [PendingApproval]) {
        state.approvals = approvals

        if !approvals.isEmpty && !isVisible {
            positionWindow()
            panel.ignoresMouseEvents = false
            panel.orderFrontRegardless()
            isVisible = true
        } else if approvals.isEmpty && isVisible {
            panel.ignoresMouseEvents = true
            // Delay to let SwiftUI collapse animation finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.state.approvals.isEmpty else { return }
                self.panel.orderOut(nil)
                self.isVisible = false
            }
        }
    }

    // Fixed position: max size, centered at screen top. Never moves.
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }

        let maxW = Constants.expandedWidth
        let maxH: CGFloat = 300

        let frame = NSRect(
            x: screen.frame.origin.x + screen.frame.width / 2 - maxW / 2,
            y: screen.frame.origin.y + screen.frame.height - maxH,
            width: maxW,
            height: maxH
        )
        panel.setFrame(frame, display: false)
    }
}
