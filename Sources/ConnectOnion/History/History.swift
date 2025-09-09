import Foundation

public struct BehaviorRecord: Codable, Sendable {
    public var timestamp: Date
    public var agent: String
    public var task: String
    public var messages: [Message]
    public var toolCalls: [ToolCall]
    public var metadata: [String: JSONValue]

    public init(timestamp: Date = Date(), agent: String, task: String, messages: [Message], toolCalls: [ToolCall] = [], metadata: [String: JSONValue] = [:]) {
        self.timestamp = timestamp
        self.agent = agent
        self.task = task
        self.messages = messages
        self.toolCalls = toolCalls
        self.metadata = metadata
    }
}

public actor HistoryStore {
    public enum Location: Sendable {
        case repoLocal(URL) // ./.connectonion
        case custom(URL)
    }

    private let baseDir: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(baseDir: URL) {
        self.baseDir = baseDir
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func append(agentName: String, record: BehaviorRecord) throws {
        let agentDir = baseDir.appending(path: "agents/\(agentName)")
        try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
        let file = agentDir.appending(path: "behavior.json")

        var records: [BehaviorRecord] = []
        if FileManager.default.fileExists(atPath: file.path) {
            let data = try Data(contentsOf: file)
            if data.count > 0 {
                records = try decoder.decode([BehaviorRecord].self, from: data)
            }
        }
        records.append(record)
        let data = try encoder.encode(records)
        try data.write(to: file, options: .atomic)
    }
}

