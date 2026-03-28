import Foundation

struct PendingApproval: Identifiable, Equatable {
    let id: String
    let toolName: String
    let summary: String

    init(from url: URL) throws {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Pester", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }

        self.id = json["session_id"] as? String ?? url.deletingPathExtension().lastPathComponent
        self.toolName = json["tool_name"] as? String ?? "Tool"
        self.summary = json["summary"] as? String ?? ""
    }
}
