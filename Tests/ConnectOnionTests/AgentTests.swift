import XCTest
@testable import ConnectOnion

final class AgentTests: XCTestCase {
    struct EchoTool: Tool {
        let name = "echo"
        let summary = "Echo input text"
        var parameters: JSONValue {
            .object([
                "type": .string("object"),
                "properties": .object([
                    "text": .object(["type": .string("string")])
                ])
            ])
        }
        func call(args: [String : JSONValue]) async throws -> JSONValue {
            if case let .string(text)? = args["text"] { return .object(["echoed": .string(text)]) }
            return .object([:])
        }
    }
    
    struct CalculatorTool: Tool {
        let name = "calculator"
        let summary = "Perform basic math operations"
        func call(args: [String : JSONValue]) async throws -> JSONValue {
            guard case let .string(op)? = args["operation"],
                  case let .number(a)? = args["a"],
                  case let .number(b)? = args["b"] else {
                return .object(["error": .string("Invalid arguments")])
            }
            
            let result: Double
            switch op {
            case "add": result = a + b
            case "subtract": result = a - b
            case "multiply": result = a * b
            case "divide": result = b != 0 ? a / b : Double.nan
            default: return .object(["error": .string("Unknown operation")])
            }
            
            return .object(["result": .number(result)])
        }
    }

    actor MockLLM: LLM {
        var calls = 0
        var responses: [LLMResponse] = []
        
        init(responses: [LLMResponse] = []) {
            self.responses = responses
        }
        
        func generate(messages: [Message], tools: [ToolSpec]?) async throws -> LLMResponse {
            if responses.isEmpty {
                // Default behavior for backward compatibility
                calls += 1
                if calls == 1 {
                    return LLMResponse(content: nil, toolCalls: [LLMToolCall(name: "echo", arguments: ["text": .string("hi")])])
                } else {
                    return LLMResponse(content: "done", toolCalls: [])
                }
            } else {
                // Use predefined responses
                guard calls < responses.count else {
                    return LLMResponse(content: "No more responses", toolCalls: [])
                }
                let response = responses[calls]
                calls += 1
                return response
            }
        }
    }

    func testAgentRunsSingleStepWithTool() async throws {
        let llm = MockLLM()
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let agent = Agent(name: "tester", llm: llm, historyDir: tmp)
        await agent.registerTool(EchoTool())
        let result = try await agent.input("echo please")
        XCTAssertEqual(result, "done")

        // Verify history was written with tool call
        let file = tmp.appending(path: "agents/tester/behavior.json")
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([BehaviorRecord].self, from: data)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].toolCalls.first?.name, "echo")
        XCTAssertEqual(records[0].messages.first?.role, .user)
    }
    
    func testAgentWithSystemPrompt() async throws {
        let responses = [
            LLMResponse(content: "I am a helpful assistant as instructed.", toolCalls: [])
        ]
        let llm = MockLLM(responses: responses)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        
        let agent = Agent(
            name: "system-prompt-test",
            llm: llm,
            historyDir: tmp,
            systemPrompt: "You are a helpful assistant."
        )
        
        let result = try await agent.input("Hello")
        XCTAssertEqual(result, "I am a helpful assistant as instructed.")
    }
    
    func testAgentWithMultipleTools() async throws {
        let responses = [
            LLMResponse(content: nil, toolCalls: [
                LLMToolCall(name: "calculator", arguments: ["operation": .string("add"), "a": .number(5), "b": .number(3)])
            ]),
            LLMResponse(content: "The result is 8", toolCalls: [])
        ]
        
        let llm = MockLLM(responses: responses)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        
        let agent = Agent(name: "multi-tool-test", llm: llm, historyDir: tmp)
        await agent.registerTools([EchoTool(), CalculatorTool()])
        
        let result = try await agent.input("Add 5 and 3")
        XCTAssertEqual(result, "The result is 8")
    }
    
    func testAgentMaxIterations() async throws {
        // Create a mock LLM that always returns tool calls (never content)
        let responses = Array(repeating: LLMResponse(
            content: nil,
            toolCalls: [LLMToolCall(name: "echo", arguments: ["text": .string("loop")])]
        ), count: 15)
        
        let llm = MockLLM(responses: responses)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        
        let agent = Agent(
            name: "max-iterations-test",
            llm: llm,
            historyDir: tmp,
            maxIterations: 3
        )
        await agent.registerTool(EchoTool())
        
        let result = try await agent.input("Keep echoing")
        // Should return empty string after max iterations
        XCTAssertEqual(result, "")
    }
    
    func testAgentWithCustomMaxIterationsPerCall() async throws {
        let responses = [
            LLMResponse(content: nil, toolCalls: [LLMToolCall(name: "echo", arguments: ["text": .string("test")])]),
            LLMResponse(content: nil, toolCalls: [LLMToolCall(name: "echo", arguments: ["text": .string("test")])]),
            LLMResponse(content: "Completed", toolCalls: [])
        ]
        
        let llm = MockLLM(responses: responses)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        
        let agent = Agent(
            name: "custom-iterations-test",
            llm: llm,
            historyDir: tmp,
            maxIterations: 1  // Default is 1
        )
        await agent.registerTool(EchoTool())
        
        // Override with custom max iterations for this call
        let result = try await agent.input("Echo twice", maxIterations: 5)
        XCTAssertEqual(result, "Completed")
    }
    
    func testAgentRegistersMultipleToolsAtOnce() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        
        let agent = Agent(name: "bulk-register-test", historyDir: tmp)
        
        let tools: [any Tool] = [EchoTool(), CalculatorTool()]
        await agent.registerTools(tools)
        
        // Verify tools are registered (we can't directly check, but this shouldn't crash)
        XCTAssertNotNil(agent)
    }
    
    func testAgentWithoutLLMUsesFactory() async throws {
        // This test verifies that agent can be created without explicit LLM
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        
        let agent = Agent(
            name: "factory-llm-test",
            historyDir: tmp,
            model: "gpt-4o-mini",
            apiKey: "test-key"
        )
        
        XCTAssertNotNil(agent)
        // Note: agent.name is actor-isolated, so we just verify agent exists
    }
}
