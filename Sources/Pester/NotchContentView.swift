import SwiftUI

struct NotchContentView: View {
    @ObservedObject var state: NotchState

    private var isOpen: Bool { !state.approvals.isEmpty }

    private var notchW: CGFloat { Constants.notchWidth }
    private var notchH: CGFloat { Constants.notchHeight }

    private var shapeWidth: CGFloat {
        isOpen ? Constants.expandedWidth : notchW
    }

    private var shapeHeight: CGFloat {
        guard isOpen else { return notchH }
        let rows = CGFloat(min(state.approvals.count, 5))
        let header: CGFloat = state.approvals.count > 1 ? Constants.countHeaderHeight : 0
        return notchH + 8 + header + rows * Constants.rowHeight + Constants.bottomPadding
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Color.black

                contentRows
                    .opacity(isOpen ? 1 : 0)
            }
            .frame(width: shapeWidth, height: shapeHeight)
            .clipShape(NotchShape(
                topCornerRadius: isOpen ? 10 : 6,
                bottomCornerRadius: isOpen ? 18 : 14
            ))
            .onTapGesture {
                if isOpen { state.onTap?() }
            }

            Spacer(minLength: 0)
        }
        .frame(width: Constants.expandedWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(.spring(duration: 0.35, bounce: 0.12), value: isOpen)
        .animation(.spring(duration: 0.3, bounce: 0.1), value: state.approvals.count)
    }

    private var contentRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: notchH + 8)

            if state.approvals.count > 1 {
                Text("\(state.approvals.count) sessions waiting")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(height: Constants.countHeaderHeight, alignment: .leading)
            }

            ForEach(state.approvals.prefix(5)) { approval in
                ApprovalRow(approval: approval)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, Constants.bottomPadding)
    }
}

struct ApprovalRow: View {
    let approval: PendingApproval

    var body: some View {
        HStack(spacing: 12) {
            ClaudeMascotView(size: 16)

            HStack(spacing: 12) {
                Text(approval.toolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                if !approval.summary.isEmpty {
                    Text(approval.summary)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()
        }
        .frame(height: Constants.rowHeight)
    }
}
