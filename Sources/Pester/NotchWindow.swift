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

        resizeWindow(height: Constants.notchHeight)
    }

    func updateApprovals(_ approvals: [PendingApproval]) {
        if !approvals.isEmpty {
            let targetHeight = contentHeight(for: approvals.count)
            let currentHeight = contentHeight(for: state.approvals.count)

            // Grow window BEFORE updating state so expand animation isn't clipped
            if targetHeight > currentHeight || !isVisible {
                resizeWindow(height: targetHeight)
            }

            state.approvals = approvals
            panel.ignoresMouseEvents = false

            if !isVisible {
                panel.orderFrontRegardless()
                isVisible = true
            }

            // Shrink window AFTER animation so collapse isn't clipped
            if targetHeight < currentHeight {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                    guard let self, !self.state.approvals.isEmpty else { return }
                    self.resizeWindow(height: self.contentHeight(for: self.state.approvals.count))
                }
            }
        } else if isVisible {
            state.approvals = []
            panel.ignoresMouseEvents = true

            // Wait for collapse animation, then hide and shrink
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.state.approvals.isEmpty else { return }
                self.panel.orderOut(nil)
                self.isVisible = false
                self.resizeWindow(height: Constants.notchHeight)
            }
        }
    }

    private func contentHeight(for count: Int) -> CGFloat {
        let notchH = Constants.notchHeight
        guard count > 0 else { return notchH }
        let rows = CGFloat(min(count, 5))
        let header: CGFloat = count > 1 ? Constants.countHeaderHeight : 0
        return notchH + 8 + header + rows * Constants.rowHeight + Constants.bottomPadding
    }

    // Pin top edge to screen top, grow/shrink downward
    private func resizeWindow(height: CGFloat) {
        guard let screen = NSScreen.main else { return }
        let w = Constants.expandedWidth
        let frame = NSRect(
            x: screen.frame.origin.x + screen.frame.width / 2 - w / 2,
            y: screen.frame.origin.y + screen.frame.height - height,
            width: w,
            height: height
        )
        panel.setFrame(frame, display: true)
    }
}
