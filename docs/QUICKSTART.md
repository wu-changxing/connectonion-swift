# Quick Start Guide

Get up and running with ConnectOnion-Swift in under 2 minutes.

## 1. Create Your Project (30 seconds)

```bash
mkdir my-agent
cd my-agent
swift package init --type executable
```

## 2. Add ConnectOnion (15 seconds)

Edit `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "my-agent",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/wu-changxing/connectonion-swift", from: "0.0.1")
    ],
    targets: [
        .executableTarget(
            name: "my-agent",
            dependencies: [
                .product(name: "ConnectOnion", package: "connectonion-swift")
            ]
        )
    ]
)
```

## 3. Set Your API Key (15 seconds)

Create `.env`:

```bash
echo "OPENAI_API_KEY=sk-your-key-here" > .env
```

## 4. Write Your Agent (30 seconds)

Replace `Sources/my-agent/main.swift`:

```swift
import ConnectOnion

@main
struct MyAgent {
    static func main() async throws {
        // Load API key from .env
        loadEnvironment()
        
        // Create agent
        let agent = Agent(name: "assistant")
        
        // Chat
        let response = try await agent.input("Hello! What can you do?")
        print(response)
    }
}
```

## 5. Run It! (30 seconds)

```bash
swift run
```

**Output:**
```
Hello! I can help you with a variety of tasks including answering questions,
providing information, helping with analysis, and having conversations...
```

🎉 **That's it! You have a working AI agent in under 2 minutes!**

---

## Make It Useful (Next 3 Minutes)

### Add a Calculator Tool (1 minute)

```swift
import ConnectOnion

// Simple calculator tool
struct Calculator: Tool {
    let name = "calculator"
    let summary = "Perform math calculations"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(op)? = args["operation"],
              case let .number(a)? = args["a"],
              case let .number(b)? = args["b"] else {
            return .object(["error": .string("Need operation, a, and b")])
        }
        
        let result: Double = switch op {
            case "add": a + b
            case "subtract": a - b
            case "multiply": a * b
            case "divide": a / b
            default: 0
        }
        
        return .object(["result": .number(result)])
    }
}

@main
struct MyAgent {
    static func main() async throws {
        loadEnvironment()
        
        let agent = Agent(name: "calculator-bot")
        await agent.registerTool(Calculator())
        
        let response = try await agent.input("What's 42 times 17?")
        print(response)  // "42 times 17 equals 714"
    }
}
```

### Make It Interactive (1 minute)

```swift
@main
struct MyAgent {
    static func main() async throws {
        loadEnvironment()
        
        let agent = Agent(name: "assistant")
        await agent.registerTool(Calculator())
        
        print("🤖 AI Assistant Ready! (type 'exit' to quit)")
        print("----------------------------------------")
        
        while let input = readLine() {
            if input == "exit" { break }
            
            do {
                let response = try await agent.input(input)
                print("AI: \(response)\n")
            } catch {
                print("Error: \(error)\n")
            }
        }
        
        print("Goodbye! 👋")
    }
}
```

### Add Memory (1 minute)

```swift
@main
struct MyAgent {
    static func main() async throws {
        loadEnvironment()
        
        let agent = Agent(
            name: "assistant",
            systemPrompt: "You are a helpful assistant who remembers our conversation."
        )
        
        var context: [Message] = []
        
        print("🤖 AI with Memory! (I'll remember everything)")
        
        while let input = readLine() {
            if input == "exit" { break }
            
            // Pass context for memory
            let response = try await agent.input(input, messages: context)
            print("AI: \(response)\n")
            
            // Update context
            context.append(Message(role: .user, content: input))
            context.append(Message(role: .assistant, content: response))
        }
    }
}
```

---

## Try These Examples

### 1. Weather Bot (Copy & Paste)

```swift
import ConnectOnion
import Foundation

func getWeather(city: String) -> String {
    let temp = Int.random(in: 60...85)
    let conditions = ["Sunny", "Cloudy", "Partly Cloudy", "Clear"].randomElement()!
    return "It's \(temp)°F and \(conditions) in \(city)"
}

@main
struct WeatherBot {
    static func main() async throws {
        loadEnvironment()
        
        let agent = Agent(
            name: "weather-bot",
            systemPrompt: "You are a friendly weather assistant."
        )
        
        await agent.registerTool(getWeather)
        
        let response = try await agent.input("What's the weather in San Francisco?")
        print(response)  // "The weather in San Francisco is 72°F and Sunny. It's a beautiful day!"
    }
}
```

### 2. File Reader (Copy & Paste)

```swift
import ConnectOnion
import Foundation

struct FileReader: Tool {
    let name = "read_file"
    let summary = "Read contents of a file"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        guard case let .string(path)? = args["path"] else {
            return .object(["error": .string("Need file path")])
        }
        
        do {
            let content = try String(contentsOfFile: path)
            return .object(["content": .string(content)])
        } catch {
            return .object(["error": .string("Cannot read file: \(error)")])
        }
    }
}

@main
struct FileBot {
    static func main() async throws {
        loadEnvironment()
        
        let agent = Agent(name: "file-bot")
        await agent.registerTool(FileReader())
        
        let response = try await agent.input("Read the Package.swift file and summarize it")
        print(response)
    }
}
```

### 3. Multi-Tool Assistant (Copy & Paste)

```swift
import ConnectOnion
import Foundation

// Time tool
func getCurrentTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: Date())
}

// Joke tool
func tellJoke() -> String {
    let jokes = [
        "Why do programmers prefer dark mode? Because light attracts bugs!",
        "Why do Swift developers never get lost? They always have a strong reference!",
        "What's a pirate's favorite programming language? R... but actually it's Swift!"
    ]
    return jokes.randomElement()!
}

// Random number tool
func randomNumber(min: Int = 1, max: Int = 100) -> Int {
    return Int.random(in: min...max)
}

@main
struct MultiBot {
    static func main() async throws {
        loadEnvironment()
        
        let agent = Agent(
            name: "multi-bot",
            systemPrompt: "You are a helpful assistant with multiple tools."
        )
        
        // Register all tools at once
        await agent.registerTools([
            getCurrentTime,
            tellJoke,
            randomNumber,
            Calculator()  // From earlier example
        ])
        
        // Try different commands
        let examples = [
            "What time is it?",
            "Tell me a joke",
            "Pick a random number between 1 and 10",
            "Calculate 15% tip on $42.50"
        ]
        
        for example in examples {
            print("You: \(example)")
            let response = try await agent.input(example)
            print("AI: \(response)\n")
        }
    }
}
```

---

## What's Next?

### 🎯 In 5 More Minutes You Can:

1. **Add Custom System Prompts**
   ```swift
   let agent = Agent(
       name: "expert",
       systemPrompt: "You are an expert in Swift programming..."
   )
   ```

2. **Use Different Models**
   ```swift
   let agent = Agent(name: "smart", model: "gpt-4")
   ```

3. **Save Conversation History**
   ```swift
   // Automatic! Check ~/.connectonion/agents/{name}/behavior.json
   ```

4. **Build a Web API**
   ```swift
   // Use with Vapor, Hummingbird, or any Swift web framework
   app.post("/chat") { req in
       let response = try await agent.input(req.body.text)
       return ["response": response]
   }
   ```

5. **Create a Desktop App**
   ```swift
   // SwiftUI example in examples/DesktopAssistantApp
   ```

### 📚 Learn More

- **[Getting Started Guide](GETTING_STARTED.md)** - Detailed walkthrough
- **[Examples](EXAMPLES.md)** - Full code examples
- **[API Reference](API.md)** - Complete API documentation
- **[Developer Experience](DEVELOPER_EXPERIENCE.md)** - Our philosophy

### 🚀 Ready-to-Run Examples

```bash
# CLI Assistant
cd examples/CLIAssistant
swift run

# Terminal UI
cd examples/CLITerminalUI
swift run

# Desktop App (macOS)
cd examples/DesktopAssistantApp
swift run
```

---

## Common Questions

### "How do I use a custom API endpoint?"

```swift
let agent = Agent(
    name: "custom",
    llm: createLLM(
        baseURL: URL(string: "https://my-api.com/v1"),
        apiKey: "my-key"
    )
)
```

### "How do I see what tools were called?"

```swift
// It's automatic! After each call:
Task: "What's 2+2?"
[1] • 15ms calculator(operation="add", a=2, b=2)
      OUT ← {"result": 4}
```

### "How do I handle errors?"

```swift
do {
    let response = try await agent.input("Hello")
} catch {
    print("Error: \(error)")
    // Errors are descriptive:
    // "Missing OPENAI_API_KEY. Set in .env or pass via apiKey parameter"
}
```

### "How do I make tools type-safe?"

```swift
struct SearchRequest: Codable {
    let query: String
    let limit: Int?
}

let tool = createTool(
    name: "search",
    summary: "Search the web",
    parameterType: SearchRequest.self
) { request in
    // request is fully typed!
    return SearchResult(items: [...])
}
```

---

## Troubleshooting

### ❌ "Missing OPENAI_API_KEY"

**Fix:**
```bash
echo "OPENAI_API_KEY=sk-your-key" > .env
```

Then in code:
```swift
loadEnvironment()  // At the start of main()
```

### ❌ "No such module 'ConnectOnion'"

**Fix:** Make sure Package.swift has the dependency:
```swift
dependencies: [
    .package(url: "https://github.com/wu-changxing/connectonion-swift", from: "0.0.1")
]
```

Then: `swift package resolve`

### ❌ "Tool not found"

**Fix:** Register the tool:
```swift
await agent.registerTool(YourTool())
```

---

## You're Ready! 🎉

You now know enough to:
- ✅ Create AI agents
- ✅ Add tools for functionality
- ✅ Build interactive apps
- ✅ Deploy to production

**Time spent: Under 5 minutes**

Remember: **If something takes more than 60 seconds to understand, we've failed.**

Happy building! 🚀