import XCTest
@testable import ConnectOnion

final class HistoryTests: XCTestCase {
    func testHistoryRoundtrip() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let store = HistoryStore(baseDir: tmp)
        let record = BehaviorRecord(
            agent: "tester",
            task: "say hi",
            messages: [Message(role: .user, content: "hi"), Message(role: .assistant, content: "hello")],
            toolCalls: [ToolCall(name: "noop", args: [:], result: .object([:]), timingMS: 1)],
            metadata: ["model": .string("gpt-4o-mini")]
        )
        try await store.append(agentName: "tester", record: record)

        let file = tmp.appending(path: "agents/tester/behavior.json")
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([BehaviorRecord].self, from: data)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].agent, "tester")
        XCTAssertEqual(decoded[0].messages.last?.content, "hello")
        XCTAssertEqual(decoded[0].toolCalls.first?.name, "noop")
    }
}
