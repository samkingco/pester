import Foundation

public enum PesterProtocol {
    public static let setNotification = Notification.Name("com.pester.notification.set")
    public static let clearNotification = Notification.Name("com.pester.notification.clear")

    public enum Key {
        public static let id = "id"
        public static let adapterId = "adapter_id"
        public static let title = "title"
        public static let summary = "summary"
    }
}

public enum AdapterID: String, Codable {
    case claude
    case pi
}
