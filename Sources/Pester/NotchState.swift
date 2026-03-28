import Foundation

final class NotchState: ObservableObject {
    @Published var approvals: [PendingApproval] = []
    var onTap: (() -> Void)?
}
