# API Reference

Quick lookup for all ConnectOnion-Swift types and methods.

## Agent

The main orchestrator for AI interactions.

### Creating an Agent

```swift
let agent = Agent(name: "assistant")
```

### Full Initializer

```swift
Agent(
    name: String,
    llm: LLM? = nil,
    historyDir: URL = URL(fileURLWithPath: ".connectonion"),
    model: String = "gpt-4o-mini",
    systemPrompt: String? = nil,
    maxIterations: Int = 10,
    apiKey: String? = nil
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| name | String | required | Unique identifier for the agent |
| llm | LLM? | nil | Custom LLM instance (auto-created if nil) |
| historyDir | URL | .connectonion | Directory for behavior history |
| model | String | gpt-4o-mini | Model to use |
| systemPrompt | String? | nil | System instructions |
| maxIterations | Int | 10 | Max tool-calling rounds |
| apiKey | String? | nil | API key (uses env if nil) |

### Methods

#### input(_:messages:maxIterations:)

Send input and get response.

```swift
let response = try await agent.input("Hello")
```

| Parameter | Type | Description |
|-----------|------|-------------|
| task | String | User input |
| messages | [Message] | Conversation context |
| maxIterations | Int? | Override max iterations |

**Returns:** `String` - Agent's response

#### registerTool(_:)

Register a single tool.

```swift
await agent.registerTool(CalculatorTool())
```

#### registerTools(_:)

Register multiple tools.

```swift
await agent.registerTools([tool1, tool2, tool3])
```

---

## Tool Protocol

Define capabilities for agents.

```swift
protocol Tool: Sendable {
    var name: String { get }
    var summary: String { get }
    var parameters: JSONValue { get }
    func call(args: [String: JSONValue]) async throws -> JSONValue
}
```

### Simple Implementation

```swift
struct TimeTool: Tool {
    let name = "get_time"
    let summary = "Get current time"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        return .string(Date().description)
    }
}
```

### With Parameters

```swift
struct SearchTool: Tool {
    let name = "search"
    let summary = "Search the web"
    
    var parameters: JSONValue {
        .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object([
                    "type": .string("string"),
                    "description": .string("Search query")
                ])
            ]),
            "required": .array([.string("query")])
        ])
    }
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(query)? = args["query"] else {
            return .object(["error": .string("Query required")])
        }
        return .object(["results": .string("Results for: \(query)")])
    }
}
```

---

## FunctionTool

Wrapper for closure-based tools.

```swift
let tool = FunctionTool(
    name: "echo",
    summary: "Echo input",
    parameters: .object([:])
) { args in
    return args["text"] ?? .string("No input")
}
```

### createTool

Type-safe tool creation with Codable.

```swift
struct Request: Codable {
    let text: String
}

struct Response: Codable {
    let result: String
}

let tool = createTool(
    name: "process",
    summary: "Process text",
    parameterType: Request.self
) { request in
    return Response(result: request.text.uppercased())
}
```

---

## Message

Represents a conversation message.

```swift
let message = Message(role: .user, content: "Hello")
```

### Role Enum

```swift
enum Role: String {
    case system     // System instructions
    case user       // User input
    case assistant  // AI response
    case tool       // Tool result
}
```

### Creating Messages

```swift
let system = Message(role: .system, content: "You are helpful")
let user = Message(role: .user, content: "Hi")
let assistant = Message(role: .assistant, content: "Hello!")
let tool = Message(role: .tool, content: "{\"result\": 42}")
```

---

## JSONValue

Type-safe JSON representation.

```swift
enum JSONValue {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
}
```

### Creating JSON

```swift
let json: JSONValue = .object([
    "name": .string("Alice"),
    "age": .number(30),
    "active": .bool(true),
    "tags": .array([.string("swift"), .string("ai")])
])
```

### Pattern Matching

```swift
switch value {
case .string(let s):
    print("String: \(s)")
case .number(let n):
    print("Number: \(n)")
case .object(let obj):
    print("Object with \(obj.count) keys")
default:
    break
}
```

---

## LLM Protocol

Interface for language models.

```swift
protocol LLM: Sendable {
    func generate(
        messages: [Message],
        tools: [ToolSpec]?
    ) async throws -> LLMResponse
}
```

### LLMResponse

```swift
struct LLMResponse {
    var content: String?          // Text response
    var toolCalls: [LLMToolCall]  // Tool requests
}
```

### LLMToolCall

```swift
struct LLMToolCall {
    var name: String                    // Tool name
    var arguments: [String: JSONValue]  // Arguments
}
```

---

## Factory Functions

### createLLM

Create an LLM instance.

```swift
let llm = createLLM(
    model: "gpt-4",
    apiKey: "sk-...",
    baseURL: URL(string: "https://api.openai.com/v1")
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| model | String | gpt-4o-mini | Model name |
| apiKey | String? | env var | API key |
| baseURL | URL? | OpenAI | API endpoint |

### loadEnvironment

Load environment variables.

```swift
loadEnvironment()              // Load from .env
loadEnvironment(from: "custom.env")  // Custom file
```

---

## History

Automatic behavior tracking.

### HistoryStore

```swift
let history = HistoryStore(baseDir: URL(...))
```

### BehaviorRecord

```swift
struct BehaviorRecord: Codable {
    let agent: String
    let task: String
    let timestamp: Date
    let messages: [Message]
    let toolCalls: [ToolCall]
    let metadata: [String: JSONValue]
}
```

### ToolCall

```swift
struct ToolCall: Codable {
    let name: String
    let args: [String: JSONValue]
    let result: JSONValue?
    let timingMS: Int?
}
```

---

## OpenAI

### OpenAIClient

OpenAI API implementation.

```swift
let client = OpenAIClient(
    config: OpenAIClient.Config(
        apiKey: "sk-...",
        model: "gpt-4",
        baseURL: URL(string: "https://api.openai.com/v1")!
    )
)
```

### Configuration

```swift
struct Config {
    let apiKey: String
    let model: String
    let baseURL: URL
    let temperature: Double = 0.7
    let maxTokens: Int? = nil
}
```

---

## Error Handling

### Common Errors

```swift
do {
    let response = try await agent.input("Hello")
} catch {
    // Detailed error messages:
    // - "Missing OPENAI_API_KEY"
    // - "Tool 'calculator' not found"
    // - "Maximum iterations (10) exceeded"
    // - "Network error: ..."
}
```

### Best Practices

```swift
// Always handle errors
do {
    let response = try await agent.input(prompt)
    processResponse(response)
} catch {
    logger.error("Agent error: \(error)")
    showUserError("Sorry, something went wrong. Please try again.")
}
```

---

## Type Helpers

### Conversion Functions

```swift
// JSONValue to Swift types
func toAny(_ value: JSONValue) -> Any
func toDictionary(_ args: [String: JSONValue]) -> [String: Any]

// Swift types to JSONValue
func fromAny(_ any: Any) -> JSONValue
```

### Usage

```swift
let json: JSONValue = .object(["count": .number(42)])
let dict = toDictionary(["count": .number(42)])
let any = toAny(json)
let back = fromAny(any)
```

---

## Complete Example

Putting it all together:

```swift
import ConnectOnion

// Define a tool
struct WeatherTool: Tool {
    let name = "weather"
    let summary = "Get weather"
    
    var parameters: JSONValue {
        .object([
            "type": .string("object"),
            "properties": .object([
                "city": .object(["type": .string("string")])
            ]),
            "required": .array([.string("city")])
        ])
    }
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(city)? = args["city"] else {
            return .object(["error": .string("City required")])
        }
        return .object([
            "city": .string(city),
            "temp": .number(72),
            "conditions": .string("Sunny")
        ])
    }
}

@main
struct App {
    static func main() async throws {
        // Setup
        loadEnvironment()
        
        // Create agent
        let agent = Agent(
            name: "weather-bot",
            systemPrompt: "You are a helpful weather assistant.",
            maxIterations: 5
        )
        
        // Add tools
        await agent.registerTool(WeatherTool())
        
        // Conversation
        var context: [Message] = []
        
        // First query
        let response1 = try await agent.input(
            "What's the weather in Paris?",
            messages: context
        )
        print(response1)
        // "The weather in Paris is 72°F and sunny!"
        
        // Update context
        context.append(Message(role: .user, content: "What's the weather in Paris?"))
        context.append(Message(role: .assistant, content: response1))
        
        // Follow-up with context
        let response2 = try await agent.input(
            "How about London?",
            messages: context
        )
        print(response2)
        // "In London, it's also 72°F and sunny!"
    }
}
```

---

## Quick Reference Card

```swift
// Create agent
let agent = Agent(name: "bot")

// Add tool
await agent.registerTool(MyTool())

// Simple query
let response = try await agent.input("Hello")

// With context
var messages: [Message] = []
let response = try await agent.input("Hi", messages: messages)
messages.append(Message(role: .user, content: "Hi"))
messages.append(Message(role: .assistant, content: response))

// Function tool
func myFunc(text: String) -> String { 
    return text.uppercased() 
}
await agent.registerTool(myFunc)

// Type-safe tool
let tool = createTool(
    name: "tool",
    summary: "Description",
    parameterType: MyRequest.self
) { request in
    return MyResponse(...)
}

// Load environment
loadEnvironment()

// Custom LLM
let llm = createLLM(model: "gpt-4", apiKey: "...")
let agent = Agent(name: "bot", llm: llm)
```