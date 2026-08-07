import Foundation
import PesterProtocol

private struct SetInput: Decodable {
    let id: String
    let adapterId: AdapterID
    let title: String
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case id
        case adapterId = "adapter_id"
        case title
        case summary
    }
}

private struct ClearInput: Decodable {
    let id: String
    let adapterId: AdapterID

    enum CodingKeys: String, CodingKey {
        case id
        case adapterId = "adapter_id"
    }
}

private struct ClaudeHookInput: Decodable {
    struct ToolInput: Decodable {
        let command: String?
        let filePath: String?
        let description: String?

        enum CodingKeys: String, CodingKey {
            case command
            case filePath = "file_path"
            case description
        }
    }

    let sessionId: String
    let toolName: String?
    let toolInput: ToolInput?
    let message: String?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case message
        case title
    }
}

private enum CLIError: Error, CustomStringConvertible {
    case invalidArguments
    case missingValue(String)

    var description: String {
        switch self {
        case .invalidArguments:
            "Usage: pester-cli [set|clear|claude set|claude clear]"
        case let .missingValue(name):
            "Missing required value: \(name)"
        }
    }
}

private func require(_ value: String, name: String) throws -> String {
    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw CLIError.missingValue(name)
    }
    return value
}

private func postSet(id: String, adapterId: AdapterID, title: String, summary: String) {
    DistributedNotificationCenter.default().postNotificationName(
        PesterProtocol.setNotification,
        object: nil,
        userInfo: [
            PesterProtocol.Key.id: id,
            PesterProtocol.Key.adapterId: adapterId.rawValue,
            PesterProtocol.Key.title: title,
            PesterProtocol.Key.summary: summary,
        ],
        deliverImmediately: true
    )
}

private func postClear(id: String, adapterId: AdapterID) {
    DistributedNotificationCenter.default().postNotificationName(
        PesterProtocol.clearNotification,
        object: nil,
        userInfo: [
            PesterProtocol.Key.id: id,
            PesterProtocol.Key.adapterId: adapterId.rawValue,
        ],
        deliverImmediately: true
    )
}

private func claudeSummary(_ input: ClaudeHookInput) -> String {
    if let command = input.toolInput?.command { return command }
    if let path = input.toolInput?.filePath { return URL(fileURLWithPath: path).lastPathComponent }
    if let description = input.toolInput?.description { return description }
    if let message = input.message { return message }
    if let title = input.title { return title }
    return ""
}

private func run() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let inputData = FileHandle.standardInput.readDataToEndOfFile()
    let decoder = JSONDecoder()

    switch arguments {
    case ["set"]:
        let input = try decoder.decode(SetInput.self, from: inputData)
        postSet(
            id: try require(input.id, name: "id"),
            adapterId: input.adapterId,
            title: try require(input.title, name: "title"),
            summary: input.summary ?? ""
        )
    case ["clear"]:
        let input = try decoder.decode(ClearInput.self, from: inputData)
        postClear(id: try require(input.id, name: "id"), adapterId: input.adapterId)
    case ["claude", "set"]:
        let input = try decoder.decode(ClaudeHookInput.self, from: inputData)
        postSet(
            id: try require(input.sessionId, name: "session_id"),
            adapterId: .claude,
            title: input.toolName ?? "Waiting",
            summary: claudeSummary(input)
        )
    case ["claude", "clear"]:
        let input = try decoder.decode(ClaudeHookInput.self, from: inputData)
        postClear(
            id: try require(input.sessionId, name: "session_id"),
            adapterId: .claude
        )
    default:
        throw CLIError.invalidArguments
    }
}

do {
    try run()
} catch {
    fputs("pester-cli: \(error)\n", stderr)
    exit(1)
}
