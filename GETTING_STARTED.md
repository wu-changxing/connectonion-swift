# Getting Started with ConnectOnion-Swift

This guide will help you get up and running with ConnectOnion-Swift in just a few minutes.

## Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode 15.0 or later (for development)
- OpenAI API key (or compatible API endpoint)

## Installation

### Option 1: Swift Package Manager (Recommended)

Add ConnectOnion to your `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyAgent",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../connectonion-swift")
    ],
    targets: [
        .executableTarget(
            name: "MyAgent",
            dependencies: [
                .product(name: "ConnectOnion", package: "connectonion-swift")
            ]
        )
    ]
)
```

### Option 2: Clone and Build

```bash
# Clone the repository
git clone https://github.com/yourusername/connectonion-swift.git
cd connectonion-swift

# Build the project
swift build

# Run tests to verify installation
swift test
```

## Configuration

### 1. Environment Setup

Create a `.env` file in your project root:

```bash
# Required
OPENAI_API_KEY=sk-your-api-key-here

# Optional
OPENAI_MODEL=gpt-4o-mini
OPENAI_BASE_URL=https://api.openai.com/v1
```

### 2. Load Environment in Your Code

```swift
import ConnectOnion

// Load environment variables at startup
loadEnvironment()

// Or load from a specific file
loadEnvironment(from: "/path/to/.env")
```

## Your First Agent

### Step 1: Create a Simple Agent

```swift
import ConnectOnion

@main
struct MyFirstAgent {
    static func main() async throws {
        // Load environment
        loadEnvironment()
        
        // Create an agent
        let agent = Agent(
            name: "assistant",
            systemPrompt: "You are a helpful AI assistant.",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        )
        
        // Get a response
        let response = try await agent.input("Hello! What can you do?")
        print("Assistant: \(response)")
    }
}
```

### Step 2: Add a Tool

```swift
// Define a simple tool
struct TimeTool: Tool {
    let name = "get_time"
    let summary = "Get the current time"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = formatter.string(from: Date())
        
        return .object(["time": .string(timeString)])
    }
}

// Register the tool with your agent
await agent.registerTool(TimeTool())

// Now the agent can tell time
let response = try await agent.input("What time is it?")
print(response)  // "The current time is 2024-01-20 15:30:45"
```

### Step 3: Maintain Conversation Context

```swift
// Keep track of conversation history
var context: [Message] = []

// First message
let response1 = try await agent.input(
    "My name is Alice", 
    messages: context
)
context.append(Message(role: .user, content: "My name is Alice"))
context.append(Message(role: .assistant, content: response1))

// Second message - agent remembers the name
let response2 = try await agent.input(
    "What's my name?", 
    messages: context
)
print(response2)  // "Your name is Alice"
```

## Common Patterns

### Pattern 1: Calculator Tool

```swift
struct CalculatorTool: Tool {
    let name = "calculator"
    let summary = "Perform basic math operations"
    
    var parameters: JSONValue {
        .object([
            "type": .string("object"),
            "properties": .object([
                "operation": .object([
                    "type": .string("string"),
                    "enum": .array([
                        .string("add"), 
                        .string("subtract"), 
                        .string("multiply"), 
                        .string("divide")
                    ])
                ]),
                "x": .object(["type": .string("number")]),
                "y": .object(["type": .string("number")])
            ]),
            "required": .array([.string("operation"), .string("x"), .string("y")])
        ])
    }
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(op)? = args["operation"],
              case let .number(x)? = args["x"],
              case let .number(y)? = args["y"] else {
            return .object(["error": .string("Invalid arguments")])
        }
        
        let result: Double
        switch op {
        case "add": result = x + y
        case "subtract": result = x - y
        case "multiply": result = x * y
        case "divide": 
            guard y != 0 else {
                return .object(["error": .string("Division by zero")])
            }
            result = x / y
        default:
            return .object(["error": .string("Unknown operation")])
        }
        
        return .object(["result": .number(result)])
    }
}
```

### Pattern 2: Type-Safe Tool with Codable

```swift
// Define your types
struct WeatherRequest: Codable {
    let city: String
    let units: String?
}

struct WeatherResponse: Codable {
    let temperature: Double
    let description: String
    let humidity: Int
}

// Create the tool
let weatherTool = createTool(
    name: "get_weather",
    summary: "Get weather for a city",
    parameterType: WeatherRequest.self
) { request in
    // Simulate weather API call
    let temp = Double.random(in: 15...30)
    let humidity = Int.random(in: 40...80)
    
    return WeatherResponse(
        temperature: temp,
        description: "Partly cloudy",
        humidity: humidity
    )
}

// Register with agent
await agent.registerTool(weatherTool)
```

### Pattern 3: File Operations Tool

```swift
struct ReadFileTool: Tool {
    let name = "read_file"
    let summary = "Read contents of a text file"
    
    var parameters: JSONValue {
        .object([
            "type": .string("object"),
            "properties": .object([
                "path": .object([
                    "type": .string("string"),
                    "description": .string("Path to the file")
                ])
            ]),
            "required": .array([.string("path")])
        ])
    }
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(path)? = args["path"] else {
            return .object(["error": .string("Path required")])
        }
        
        // Security: Only allow reading from specific directories
        let allowedDir = FileManager.default.currentDirectoryPath
        let fullPath = URL(fileURLWithPath: path)
        
        guard fullPath.path.hasPrefix(allowedDir) else {
            return .object(["error": .string("Access denied")])
        }
        
        do {
            let content = try String(contentsOf: fullPath)
            return .object([
                "content": .string(content),
                "path": .string(path)
            ])
        } catch {
            return .object(["error": .string(error.localizedDescription)])
        }
    }
}
```

## Building a CLI Application

Here's a complete example of a CLI assistant:

```swift
import Foundation
import ConnectOnion

@main
struct CLIAssistant {
    static func main() async {
        // Load environment
        loadEnvironment()
        
        // Create agent
        let agent = Agent(
            name: "cli-assistant",
            systemPrompt: "You are a helpful command-line assistant.",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        )
        
        // Register tools
        await agent.registerTools([
            TimeTool(),
            CalculatorTool()
        ])
        
        // Conversation context
        var context: [Message] = []
        
        print("🤖 CLI Assistant Ready!")
        print("Type 'exit' to quit, 'clear' to reset context")
        print("----------------------------------------")
        
        while true {
            print("\nYou> ", terminator: "")
            guard let input = readLine() else { break }
            
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty { continue }
            if trimmed == "exit" { break }
            if trimmed == "clear" {
                context.removeAll()
                print("Context cleared!")
                continue
            }
            
            do {
                let response = try await agent.input(trimmed, messages: context)
                print("\nAssistant> \(response)")
                
                // Update context
                context.append(Message(role: .user, content: trimmed))
                context.append(Message(role: .assistant, content: response))
            } catch {
                print("Error: \(error)")
            }
        }
        
        print("\n👋 Goodbye!")
    }
}
```

## Debugging and Troubleshooting

### Enable Verbose Logging

```swift
// Check behavior history
let historyPath = "~/.connectonion/agents/\(agentName)/behavior.json"
print("History saved to: \(historyPath)")
```

### Common Issues

1. **"Missing OPENAI_API_KEY"**
   - Ensure your `.env` file exists and contains the key
   - Call `loadEnvironment()` before creating agents
   - Check environment: `echo $OPENAI_API_KEY`

2. **"Tool not found"**
   - Verify tool is registered: `await agent.registerTool(tool)`
   - Check tool name matches exactly

3. **"Maximum iterations exceeded"**
   - Increase limit: `Agent(maxIterations: 20)`
   - Or per-call: `agent.input(prompt, maxIterations: 15)`

4. **Network errors**
   - Check internet connection
   - Verify API endpoint is accessible
   - Check API key is valid

## Next Steps

1. **Explore Examples**
   - `examples/CLIAssistant` - Basic CLI tool
   - `examples/CLITerminalUI` - Terminal UI with colors
   - `examples/DesktopAssistantApp` - macOS SwiftUI app

2. **Read the Documentation**
   - [README.md](README.md) - Complete feature overview
   - [API Reference](docs/API.md) - Detailed API documentation

3. **Build Your Own Tools**
   - Start with simple tools
   - Use type-safe `createTool` for complex tools
   - Share tools with the community

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/yourusername/connectonion-swift/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/connectonion-swift/discussions)
- **Examples**: Check the `examples/` directory

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Happy building with ConnectOnion-Swift! 🚀