import Foundation

struct PendingNotification: Identifiable, Equatable {
    let id: String
    let adapter: AdapterDefinition
    let title: String
    let summary: String
}
