# Developer Experience Philosophy

## Core Belief

**"Build AI agents in 60 seconds, understand them in 5 minutes, master them when you need to."**

## The ConnectOnion-Swift Experience

### 1. Start with Success

```swift
// Your first agent in 3 lines
let agent = Agent(name: "assistant")
let response = try await agent.input("Hello!")
print(response)  // "Hi there! How can I help you?"
```

That's it! You have a working AI agent.

### 2. Progressive Complexity

#### Level 1: Basic (60 seconds)
```swift
let agent = Agent(name: "helper")
```

#### Level 2: Configured (2 minutes)
```swift
let agent = Agent(
    name: "helper",
    systemPrompt: "You are a helpful assistant."
)
```

#### Level 3: With Tools (5 minutes)
```swift
struct TimeTool: Tool {
    let name = "time"
    let summary = "Get current time"
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        return .string(Date().description)
    }
}

await agent.registerTool(TimeTool())
```

#### Level 4: Production Ready (when needed)
```swift
let agent = Agent(
    name: "production-assistant",
    llm: createLLM(model: "gpt-4", apiKey: secureKey),
    historyDir: customHistoryURL,
    systemPrompt: loadPrompt("system.md"),
    maxIterations: 20
)

await agent.registerTools(loadToolsFromDirectory("tools/"))
```

## Design Principles

### 1. Convention Over Configuration

**Default Everything**
```swift
// These all work out of the box:
Agent(name: "bot")                    // Uses env vars, gpt-4o-mini
Agent(name: "bot", apiKey: "sk-...")  // Custom key
Agent(name: "bot", model: "gpt-4")    // Custom model
```

### 2. Type Safety Without Ceremony

**Simple Types**
```swift
// No complex generics or protocols needed
let message = Message(role: .user, content: "Hello")
let json: JSONValue = .string("simple")
```

**But Type-Safe When You Want**
```swift
// Codable support for complex tools
struct WeatherRequest: Codable {
    let city: String
}

let tool = createTool(
    name: "weather",
    summary: "Get weather",
    parameterType: WeatherRequest.self
) { request in
    // Full type safety here
    return WeatherResponse(temp: 72, city: request.city)
}
```

### 3. Errors That Help

**Clear Error Messages**
```swift
// ❌ Bad: "Operation failed"
// ✅ Good: "Missing OPENAI_API_KEY. Set it in .env or pass via apiKey parameter"

// ❌ Bad: "Tool error"
// ✅ Good: "Tool 'calculator' requires 'operation' parameter (add/subtract/multiply/divide)"
```

### 4. Observable by Default

**Automatic Behavior Tracking**
```swift
// Every interaction is saved automatically
let agent = Agent(name: "tracker")
// History at: ~/.connectonion/agents/tracker/behavior.json

// Check what happened
let history = try await agent.getHistory()
print("Tool calls: \(history.toolCalls)")
print("Messages: \(history.messages)")
```

### 5. Composable Tools

**Mix and Match**
```swift
// Built-in tools
let calculator = CalculatorTool()

// Function tools
func search(query: String) -> String {
    return "Results for: \(query)"
}

// Type-safe tools
let weatherTool = createTool(...) { ... }

// Register all at once
await agent.registerTools([
    calculator,
    search,
    weatherTool
])
```

## What Great Developer Experience Looks Like

### 🎯 Quick Start (60 seconds)

```swift
// 1. Install
// swift package init --type executable
// Add ConnectOnion to Package.swift

// 2. Create .env
// OPENAI_API_KEY=sk-...

// 3. Write code
import ConnectOnion

@main
struct MyApp {
    static func main() async throws {
        loadEnvironment()
        let agent = Agent(name: "assistant")
        let response = try await agent.input("Hello!")
        print(response)
    }
}

// 4. Run
// swift run
```

### 🔧 Adding Capabilities (2 minutes)

```swift
// Need calculator? One line:
await agent.registerTool(CalculatorTool())

// Need custom logic? Just a function:
func getWeather(city: String) -> String {
    return "Sunny in \(city)"
}
await agent.registerTool(getWeather)

// Need complex tool? Still simple:
struct DatabaseTool: Tool {
    let name = "database"
    let summary = "Query database"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        // Your logic here
        return .object(["result": .string("data")])
    }
}
```

### 📊 Understanding What Happened (instant)

```swift
// See what the agent did
Task: "What's 2+2?"
[1] • 15ms calculator(operation="add", a=2, b=2)
      OUT ← {"result": 4}
Response: "2 plus 2 equals 4"

// In code:
let history = agent.behaviorHistory
for call in history.last?.toolCalls ?? [] {
    print("\(call.name): \(call.timingMS)ms")
}
```

### 🚀 Scaling Up (when ready)

```swift
// Parallel agents
await withTaskGroup(of: String.self) { group in
    for task in tasks {
        group.addTask {
            try await agent.input(task)
        }
    }
}

// Custom LLM endpoints
let llm = createLLM(
    model: "claude-3",
    baseURL: URL(string: "https://custom-api.com")
)

// Persistent context
var context = ConversationContext()
context.append(userMessage)
let response = try await agent.input(message, context: context)
context.append(response)
```

## Common Patterns Made Simple

### Chat Interface
```swift
while let input = readLine() {
    let response = try await agent.input(input)
    print("AI: \(response)")
}
```

### Web API
```swift
app.post("/chat") { req in
    let message = try req.content.decode(ChatRequest.self)
    let response = try await agent.input(message.text)
    return ChatResponse(text: response)
}
```

### CLI Tool
```swift
import ArgumentParser

@main
struct CLI: AsyncParsableCommand {
    @Argument var prompt: String
    
    func run() async throws {
        let agent = Agent(name: "cli")
        print(try await agent.input(prompt))
    }
}
```

### Desktop App
```swift
// SwiftUI
struct ContentView: View {
    @State private var input = ""
    @State private var response = ""
    let agent = Agent(name: "desktop")
    
    var body: some View {
        VStack {
            TextField("Ask anything...", text: $input)
            Button("Send") {
                Task {
                    response = try await agent.input(input)
                }
            }
            Text(response)
        }
    }
}
```

## Anti-Patterns We Avoid

### ❌ Configuration Hell
```swift
// We DON'T do this:
let config = AgentConfigBuilder()
    .withLLMConfig(LLMConfig())
    .withToolRegistry(ToolRegistry())
    .withHistoryManager(HistoryManager())
    .build()
```

### ❌ Callback Pyramids
```swift
// We DON'T do this:
agent.input(prompt) { result in
    result.onSuccess { response in
        response.processTools { tools in
            // ...
        }
    }
}
```

### ❌ Magic Strings
```swift
// We DON'T do this:
agent.setOption("max_iterations", "10")
agent.callTool("calculator", ["op": "add"])
```

### ❌ Verbose Ceremony
```swift
// We DON'T do this:
let factory = AgentFactory.shared
let builder = factory.createBuilder()
let agent = builder.buildAgent()
```

## Instead We Do

### ✅ Smart Defaults
```swift
let agent = Agent(name: "bot")  // Just works
```

### ✅ Async/Await
```swift
let response = try await agent.input("Hello")
```

### ✅ Type Safety
```swift
let message = Message(role: .user, content: "Hi")
agent.maxIterations = 10  // Compiler-checked
```

### ✅ Direct Construction
```swift
let agent = Agent(name: "bot")  // Done
```

## The 10-Minute Test

A developer should be able to:

1. **Minute 1-2**: Install and run first agent
2. **Minute 3-4**: Add a simple tool
3. **Minute 5-6**: Handle conversation context
4. **Minute 7-8**: Check behavior history
5. **Minute 9-10**: Deploy to production

If any step takes longer, we've failed.

## Error Messages That Teach

### Bad ❌
```
Error: Invalid configuration
```

### Good ✅
```
Missing OPENAI_API_KEY

To fix:
1. Create a .env file
2. Add: OPENAI_API_KEY=sk-your-key-here
3. Call loadEnvironment() at startup

Or pass directly:
Agent(name: "bot", apiKey: "sk-...")
```

## Documentation That Shows

### Bad ❌
```markdown
The Agent class provides an abstraction layer for LLM interactions
with support for tool calling and behavior tracking through a 
pluggable architecture...
```

### Good ✅
```swift
// Build an agent that can search the web
let agent = Agent(name: "searcher")
await agent.registerTool(WebSearchTool())

let result = try await agent.input("Find Swift tutorials")
// "I found 5 great Swift tutorials for you..."
```

## Testing Made Natural

```swift
// Test with mock LLM
let mockLLM = MockLLM(responses: [
    "Hello there!",
    "The answer is 42"
])

let agent = Agent(name: "test", llm: mockLLM)
let response = try await agent.input("Hi")
XCTAssertEqual(response, "Hello there!")
```

## Performance You Don't Think About

- **Automatic batching** of tool calls
- **Concurrent execution** when possible
- **Smart caching** of repeated queries
- **Efficient history storage** with compression

All happening behind the scenes.

## The Ultimate Test

Can a developer explain ConnectOnion-Swift to a colleague in one sentence?

**"It's a Swift framework where you create an AI agent in one line, add tools as functions, and it handles everything else."**

If they can't, we need to simplify.

## Summary

Great developer experience means:

1. **Works in 60 seconds** - No setup maze
2. **Readable code** - Looks like pseudocode
3. **Helpful errors** - Tell me how to fix it
4. **Progressive disclosure** - Complex only when needed
5. **Type-safe but not type-heavy** - Swift's sweet spot
6. **Observable by default** - See what happened
7. **Composable pieces** - Mix and match
8. **No magic** - I can understand it
9. **Production-ready** - Scales when I need it
10. **Fun to use** - Makes me want to build more

Every decision should make developers think: **"Of course that's how it works!"**