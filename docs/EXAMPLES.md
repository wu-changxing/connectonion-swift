# ConnectOnion-Swift Examples

This document provides comprehensive examples of using ConnectOnion-Swift for various use cases.

## Table of Contents

1. [Basic Examples](#basic-examples)
2. [Tool Examples](#tool-examples)
3. [Advanced Patterns](#advanced-patterns)
4. [Real-World Applications](#real-world-applications)

## Basic Examples

### Simple Q&A Agent

```swift
import ConnectOnion

// Create a basic Q&A agent
let agent = Agent(
    name: "qa-bot",
    systemPrompt: "You are a knowledgeable assistant. Answer questions accurately and concisely.",
    apiKey: "your-api-key"
)

// Ask questions
let answer = try await agent.input("What is the capital of France?")
print(answer)  // "The capital of France is Paris."
```

### Conversational Agent with Memory

```swift
// Agent that remembers conversation context
let agent = Agent(
    name: "memory-bot",
    systemPrompt: "You are a friendly assistant who remembers our conversation."
)

var context: [Message] = []

// First interaction
let response1 = try await agent.input(
    "My favorite color is blue",
    messages: context
)
context.append(Message(role: .user, content: "My favorite color is blue"))
context.append(Message(role: .assistant, content: response1))

// Later in conversation
let response2 = try await agent.input(
    "What's my favorite color?",
    messages: context
)
print(response2)  // "Your favorite color is blue!"
```

### Multi-Turn Task Assistant

```swift
// Agent for complex multi-step tasks
let agent = Agent(
    name: "task-assistant",
    systemPrompt: """
    You are a task management assistant. Help users break down 
    complex tasks into manageable steps and track progress.
    """,
    maxIterations: 15  // Allow more tool calls for complex tasks
)

// Process a complex request
let plan = try await agent.input("""
    I need to organize a team meeting next week. 
    Help me plan the agenda, send invites, and prepare materials.
""")
```

## Tool Examples

### 1. Database Query Tool

```swift
struct DatabaseTool: Tool {
    let name = "query_database"
    let summary = "Execute SQL queries on the database"
    
    var parameters: JSONValue {
        .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object([
                    "type": .string("string"),
                    "description": .string("SQL query to execute")
                ]),
                "database": .object([
                    "type": .string("string"),
                    "enum": .array([.string("users"), .string("products"), .string("orders")])
                ])
            ]),
            "required": .array([.string("query"), .string("database")])
        ])
    }
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(query)? = args["query"],
              case let .string(database)? = args["database"] else {
            return .object(["error": .string("Invalid arguments")])
        }
        
        // Security: Only allow SELECT queries
        guard query.lowercased().starts(with: "select") else {
            return .object(["error": .string("Only SELECT queries allowed")])
        }
        
        // Simulate database query
        let results = [
            ["id": 1, "name": "Alice", "email": "alice@example.com"],
            ["id": 2, "name": "Bob", "email": "bob@example.com"]
        ]
        
        return .object([
            "database": .string(database),
            "query": .string(query),
            "results": .array(results.map { row in
                .object(row.mapValues { .string("\($0)") })
            }),
            "count": .number(Double(results.count))
        ])
    }
}

// Use with agent
await agent.registerTool(DatabaseTool())
let result = try await agent.input("Show me all users whose name starts with A")
```

### 2. Web Search Tool

```swift
struct WebSearchTool: Tool {
    let name = "web_search"
    let summary = "Search the web for information"
    
    var parameters: JSONValue {
        .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object([
                    "type": .string("string"),
                    "description": .string("Search query")
                ]),
                "max_results": .object([
                    "type": .string("integer"),
                    "default": .number(5)
                ])
            ]),
            "required": .array([.string("query")])
        ])
    }
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(query)? = args["query"] else {
            return .object(["error": .string("Query required")])
        }
        
        let maxResults = args["max_results"].flatMap {
            if case let .number(n) = $0 { return Int(n) } else { return nil }
        } ?? 5
        
        // Simulate web search results
        let results = (1...maxResults).map { i in
            return [
                "title": "Result \(i) for: \(query)",
                "url": "https://example.com/result\(i)",
                "snippet": "This is a snippet for result \(i) about \(query)..."
            ]
        }
        
        return .object([
            "query": .string(query),
            "results": .array(results.map { r in
                .object(r.mapValues { .string($0) })
            })
        ])
    }
}
```

### 3. Email Tool

```swift
// Type-safe email tool using Codable
struct EmailRequest: Codable {
    let to: String
    let subject: String
    let body: String
    let cc: String?
    let attachments: [String]?
}

struct EmailResponse: Codable {
    let success: Bool
    let messageId: String?
    let error: String?
}

let emailTool = createTool(
    name: "send_email",
    summary: "Send an email",
    parameterType: EmailRequest.self
) { request in
    // Validate email
    guard request.to.contains("@") else {
        return EmailResponse(
            success: false,
            messageId: nil,
            error: "Invalid email address"
        )
    }
    
    // Simulate sending email
    let messageId = UUID().uuidString
    print("📧 Sending email to \(request.to)")
    print("   Subject: \(request.subject)")
    
    return EmailResponse(
        success: true,
        messageId: messageId,
        error: nil
    )
}

// Register and use
await agent.registerTool(emailTool)
let response = try await agent.input("""
    Send an email to john@example.com welcoming them to our service.
    Make it friendly and professional.
""")
```

### 4. Code Execution Tool

```swift
struct CodeExecutor: Tool {
    let name = "execute_code"
    let summary = "Execute Swift code snippets safely"
    
    var parameters: JSONValue {
        .object([
            "type": .string("object"),
            "properties": .object([
                "code": .object([
                    "type": .string("string"),
                    "description": .string("Swift code to execute")
                ]),
                "timeout": .object([
                    "type": .string("integer"),
                    "default": .number(5),
                    "description": .string("Timeout in seconds")
                ])
            ]),
            "required": .array([.string("code")])
        ])
    }
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(code)? = args["code"] else {
            return .object(["error": .string("Code required")])
        }
        
        // Security: Only allow safe operations
        let forbidden = ["FileManager", "Process", "system", "exec"]
        for keyword in forbidden {
            if code.contains(keyword) {
                return .object(["error": .string("Forbidden operation: \(keyword)")])
            }
        }
        
        // Create temporary Swift file
        let tempDir = FileManager.default.temporaryDirectory
        let sourceFile = tempDir.appendingPathComponent("temp_\(UUID()).swift")
        
        // Wrap code in a safe execution context
        let wrappedCode = """
        import Foundation
        
        // User code
        \(code)
        """
        
        try wrappedCode.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Compile and run
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = [sourceFile.path]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        try process.run()
        process.waitUntilExit()
        
        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        
        // Clean up
        try? FileManager.default.removeItem(at: sourceFile)
        
        return .object([
            "output": .string(output),
            "exitCode": .number(Double(process.terminationStatus))
        ])
    }
}
```

## Advanced Patterns

### 1. Tool Chaining

```swift
// Agent that chains multiple tools together
let agent = Agent(
    name: "research-assistant",
    systemPrompt: """
    You are a research assistant. When asked to research a topic:
    1. Search the web for information
    2. Query relevant databases
    3. Summarize findings
    4. Send results via email
    """
)

// Register multiple tools
await agent.registerTools([
    WebSearchTool(),
    DatabaseTool(),
    emailTool
])

// Complex request that uses multiple tools
let result = try await agent.input("""
    Research recent developments in quantum computing and 
    email a summary to the team@example.com
""")
```

### 2. Conditional Tool Usage

```swift
struct ConditionalTool: Tool {
    let name = "smart_action"
    let summary = "Performs different actions based on conditions"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(action)? = args["action"] else {
            return .object(["error": .string("Action required")])
        }
        
        switch action {
        case "analyze":
            // Perform analysis
            return .object(["result": .string("Analysis complete")])
            
        case "optimize":
            // Run optimization
            return .object(["result": .string("Optimization complete")])
            
        case "report":
            // Generate report
            return .object(["result": .string("Report generated")])
            
        default:
            return .object(["error": .string("Unknown action")])
        }
    }
}
```

### 3. Parallel Tool Execution

```swift
// Tools that can work in parallel
struct ParallelAgent {
    let agent: Agent
    
    func processMultipleTasks(_ tasks: [String]) async throws -> [String] {
        // Execute tasks in parallel
        return try await withThrowingTaskGroup(of: String.self) { group in
            for task in tasks {
                group.addTask {
                    return try await agent.input(task)
                }
            }
            
            var results: [String] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// Use parallel execution
let parallelAgent = ParallelAgent(agent: agent)
let results = try await parallelAgent.processMultipleTasks([
    "Calculate 15 * 7",
    "What's the weather in New York?",
    "Search for Swift tutorials"
])
```

### 4. State Management

```swift
// Agent with persistent state
actor StatefulAgent {
    private let agent: Agent
    private var state: [String: Any] = [:]
    
    init(agent: Agent) {
        self.agent = agent
    }
    
    func setState(key: String, value: Any) {
        state[key] = value
    }
    
    func getState(key: String) -> Any? {
        return state[key]
    }
    
    func processWithState(_ input: String) async throws -> String {
        // Add state context to prompt
        let stateContext = state.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let enhancedInput = """
        Current state: \(stateContext)
        User input: \(input)
        """
        
        return try await agent.input(enhancedInput)
    }
}
```

## Real-World Applications

### 1. Customer Support Bot

```swift
struct SupportBot {
    let agent: Agent
    
    init() {
        agent = Agent(
            name: "support-bot",
            systemPrompt: """
            You are a helpful customer support agent for TechCorp.
            Be professional, empathetic, and solution-oriented.
            Our products include: CloudSync, DataVault, and SecureChat.
            Always try to resolve issues or escalate appropriately.
            """
        )
    }
    
    func handleTicket(_ ticket: String) async throws -> String {
        // Process support ticket
        let response = try await agent.input(ticket)
        
        // Log interaction
        logInteraction(ticket: ticket, response: response)
        
        return response
    }
    
    private func logInteraction(ticket: String, response: String) {
        // Save to database or file
        print("📝 Logged support interaction")
    }
}
```

### 2. Code Review Assistant

```swift
struct CodeReviewTool: Tool {
    let name = "review_code"
    let summary = "Review code for issues and improvements"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(code)? = args["code"],
              case let .string(language)? = args["language"] else {
            return .object(["error": .string("Code and language required")])
        }
        
        var issues: [[String: String]] = []
        var suggestions: [String] = []
        
        // Simple code analysis
        if code.contains("force unwrap") || code.contains("!") {
            issues.append([
                "type": "warning",
                "message": "Avoid force unwrapping - use optional binding instead"
            ])
        }
        
        if !code.contains("// MARK:") && code.count > 100 {
            suggestions.append("Consider adding MARK comments for better organization")
        }
        
        if code.contains("print(") {
            issues.append([
                "type": "info",
                "message": "Remove debug print statements before production"
            ])
        }
        
        return .object([
            "language": .string(language),
            "issues": .array(issues.map { issue in
                .object(issue.mapValues { .string($0) })
            }),
            "suggestions": .array(suggestions.map { .string($0) }),
            "score": .number(Double(100 - issues.count * 10))
        ])
    }
}

// Code review agent
let reviewAgent = Agent(
    name: "code-reviewer",
    systemPrompt: """
    You are an expert code reviewer. Analyze code for:
    - Security vulnerabilities
    - Performance issues
    - Code style and best practices
    - Potential bugs
    Provide constructive feedback with examples.
    """
)

await reviewAgent.registerTool(CodeReviewTool())

let review = try await reviewAgent.input("""
    Review this Swift code:
    ```swift
    func fetchUser(id: String) -> User? {
        let data = database.query("SELECT * FROM users WHERE id = \(id)")
        let user = User(data: data!)
        print("Fetched user: \(user)")
        return user
    }
    ```
""")
```

### 3. Data Analysis Pipeline

```swift
struct DataAnalyzer {
    let agent: Agent
    
    init() async {
        agent = Agent(
            name: "data-analyzer",
            systemPrompt: """
            You are a data analysis expert. Analyze datasets,
            identify patterns, generate insights, and create
            visualizations when appropriate.
            """
        )
        
        // Register analysis tools
        await agent.registerTools([
            StatisticsTool(),
            VisualizationTool(),
            ReportGeneratorTool()
        ])
    }
    
    func analyzeDataset(_ data: [[String: Any]]) async throws -> AnalysisReport {
        // Convert data to string representation
        let dataString = describeData(data)
        
        // Get analysis from agent
        let analysis = try await agent.input("""
            Analyze this dataset and provide insights:
            \(dataString)
            
            Please:
            1. Calculate key statistics
            2. Identify trends or patterns
            3. Suggest visualizations
            4. Provide actionable recommendations
        """)
        
        return AnalysisReport(
            summary: analysis,
            dataPoints: data.count,
            timestamp: Date()
        )
    }
    
    private func describeData(_ data: [[String: Any]]) -> String {
        // Create summary of data structure and sample
        guard let first = data.first else { return "Empty dataset" }
        
        let columns = first.keys.joined(separator: ", ")
        let sample = data.prefix(5).map { row in
            row.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        }.joined(separator: "\n")
        
        return """
        Columns: \(columns)
        Total rows: \(data.count)
        Sample data:
        \(sample)
        """
    }
}

struct AnalysisReport {
    let summary: String
    let dataPoints: Int
    let timestamp: Date
}
```

### 4. Automated Testing Assistant

```swift
struct TestGenerator {
    let agent: Agent
    
    init() async {
        agent = Agent(
            name: "test-generator",
            systemPrompt: """
            You are an expert at writing comprehensive unit tests.
            Generate tests that:
            - Cover edge cases
            - Test error conditions
            - Verify expected behavior
            - Use appropriate assertions
            Follow XCTest conventions for Swift.
            """
        )
        
        await agent.registerTool(CodeExecutor())
    }
    
    func generateTests(for code: String) async throws -> String {
        return try await agent.input("""
            Generate comprehensive unit tests for this code:
            
            ```swift
            \(code)
            ```
            
            Include tests for:
            - Normal operation
            - Edge cases
            - Error conditions
            - Performance (if applicable)
        """)
    }
}

// Usage
let testGen = TestGenerator()
let tests = try await testGen.generateTests(for: """
    func fibonacci(_ n: Int) -> Int {
        if n <= 1 { return n }
        return fibonacci(n - 1) + fibonacci(n - 2)
    }
""")
```

## Best Practices

### 1. Tool Design

- **Single Responsibility**: Each tool should do one thing well
- **Clear Parameters**: Use descriptive parameter names and schemas
- **Error Handling**: Return informative error messages
- **Security**: Validate inputs and limit dangerous operations

### 2. Agent Configuration

- **System Prompts**: Be specific about agent behavior and constraints
- **Iteration Limits**: Set appropriate limits for tool-calling rounds
- **Context Management**: Keep conversation context when needed

### 3. Performance

- **Parallel Execution**: Use Swift concurrency for parallel tasks
- **Caching**: Cache expensive operations when appropriate
- **Batch Operations**: Group related operations together

### 4. Testing

- **Mock Tools**: Create mock tools for testing
- **Mock LLM**: Use MockLLM for unit tests
- **Behavior Verification**: Check behavior history for debugging

## Conclusion

These examples demonstrate the flexibility and power of ConnectOnion-Swift. Start with simple agents and tools, then gradually build more complex systems as your needs grow.

For more examples, check the `examples/` directory in the repository.