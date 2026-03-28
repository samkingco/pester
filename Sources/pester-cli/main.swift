import Foundation

// Usage: echo '{"session_id":"...","tool_name":"Bash",...}' | pester-cli set
//        echo '{"session_id":"..."}' | pester-cli clear

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: pester-cli [set|clear]\n", stderr)
    exit(1)
}

let action = CommandLine.arguments[1]
let inputData = FileHandle.standardInput.readDataToEndOfFile()

let pendingDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".pester/pending")
try? FileManager.default.createDirectory(at: pendingDir, withIntermediateDirectories: true)

// Parse session_id from input JSON
guard let json = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any],
      let sessionId = json["session_id"] as? String
else {
    fputs("Could not parse session_id from input\n", stderr)
    exit(1)
}

let pendingFile = pendingDir.appendingPathComponent("\(sessionId).json")

switch action {
case "set":
    let toolName = json["tool_name"] as? String ?? "Tool"
    let toolInput = json["tool_input"] as? [String: Any] ?? [:]

    var summary = ""
    if let command = toolInput["command"] as? String {
        summary = command
    } else if let path = toolInput["file_path"] as? String {
        summary = URL(fileURLWithPath: path).lastPathComponent
    } else if let desc = toolInput["description"] as? String {
        summary = desc
    } else if let message = json["message"] as? String {
        summary = message
    }

    if summary.count > 120 {
        summary = String(summary.prefix(117)) + "..."
    }

    let output: [String: Any] = [
        "session_id": sessionId,
        "tool_name": toolName,
        "summary": summary,
    ]

    if let data = try? JSONSerialization.data(withJSONObject: output) {
        try? data.write(to: pendingFile)
    }

case "clear":
    try? FileManager.default.removeItem(at: pendingFile)

default:
    fputs("Unknown action: \(action). Use 'set' or 'clear'.\n", stderr)
    exit(1)
}
