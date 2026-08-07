import Foundation

final class NotchState: ObservableObject {
    @Published var notifications: [PendingNotification] = []
    var onTap: (() -> Void)?
}
