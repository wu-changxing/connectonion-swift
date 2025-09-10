# Documentation Principles

## Core Philosophy

**"Show, don't tell"** - Every concept should be immediately usable.

## The 7 Principles

### 1. Start with Success

```markdown
BAD:  "ConnectOnion-Swift uses protocol-oriented design with actor-based concurrency..."
GOOD: "Build your first AI agent in 60 seconds."
```

Real example:
```swift
// 60 seconds to working agent
let agent = Agent(name: "bot")
let response = try await agent.input("Hello!")
```

### 2. One Concept Per Page

```markdown
BAD:  "Agents, Tools, and History" (one page)
GOOD: "Agents" | "Tools" | "History" (separate pages)
```

Each concept gets its own focused explanation:
- **Agents** - Just about creating and using agents
- **Tools** - Just about adding capabilities
- **History** - Just about behavior tracking

### 3. Code First, Explanation Second

```markdown
GOOD:
```swift
// Add memory to your agent
var context: [Message] = []
let response = try await agent.input("Hi", messages: context)
context.append(Message(role: .user, content: "Hi"))
```
That's it! Pass `context` to maintain conversation history.

BAD:
"The context management system provides stateful conversation persistence through..."
```

### 4. Progressive Disclosure

```
Level 1: Quick Start (60 seconds)
    let agent = Agent(name: "bot")
    
Level 2: Basic Usage (2 minutes)
    let agent = Agent(name: "bot", systemPrompt: "...")
    
Level 3: Advanced Patterns (5 minutes)
    let agent = Agent(
        name: "bot",
        llm: customLLM,
        historyDir: customPath,
        maxIterations: 20
    )
    
Level 4: Deep Dive (when needed)
    // Custom tool protocols, LLM implementations, etc.
```

### 5. Real Output, Not Promises

```markdown
GOOD:
Task: "What's 2+2?"
[1] • 15ms calculator(operation="add", a=2, b=2)
      OUT ← {"result": 4}
Response: "2 + 2 equals 4"

BAD:
"The tool execution system will display timing information"
```

Always show actual output from running code.

### 6. Practical Examples Only

```markdown
GOOD: "Build a weather bot that checks real forecasts"
BAD:  "Process abstract data with generic handler"

GOOD: "Create a customer support agent"
BAD:  "Implement theoretical agent patterns"
```

Every example should be something developers actually want to build.

### 7. Scannable Structure

```markdown
GOOD Structure:
## Quick Example      (3 lines of code)
## What You Get       (bullet points)
## Real Example       (10 lines max)
## Common Patterns    (2-3 patterns)
## Tips              (4 items max)

BAD Structure:
Long paragraphs explaining theory...
Complex architectural discussions...
Abstract concepts without examples...
```

## Writing Checklist

Before publishing any doc:

- [ ] Can someone use this in 60 seconds?
- [ ] Is the first example under 5 lines?
- [ ] Does it show real output?
- [ ] One main concept only?
- [ ] Mobile-friendly line lengths?
- [ ] Would I read this if I was in a hurry?

## Swift-Specific Guidelines

### Show Swift's Strengths

```swift
// Type safety without verbosity
let message = Message(role: .user, content: "Hello")

// Async/await clarity
let response = try await agent.input("Hi")

// Protocol simplicity
struct MyTool: Tool {
    let name = "my_tool"
    let summary = "Does something"
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        return .string("Done!")
    }
}
```

### Avoid Swift's Complexity

```swift
// ❌ DON'T show this in basic docs:
protocol ToolProtocol: Sendable where Self: Hashable {
    associatedtype Parameters: Codable
    func execute<T: LLMProtocol>(_ params: Parameters, llm: T) async throws
}

// ✅ DO show this:
struct SimpleTool: Tool {
    let name = "simple"
    let summary = "A simple tool"
}
```

## Examples of Good Documentation

### Quick Start Pattern

```markdown
# Weather Bot in 60 Seconds

```swift
let agent = Agent(name: "weather")
await agent.registerTool(WeatherTool())
let forecast = try await agent.input("Weather in NYC?")
print(forecast)  // "It's 72°F and sunny in New York City"
```

That's it! You have a weather bot.

## How It Works
The agent uses the WeatherTool to fetch real forecasts...
```

### Feature Introduction Pattern

```markdown
# Tools

Give your agent superpowers with tools.

```swift
func searchWeb(query: String) -> String {
    return "Results for: \(query)"
}

await agent.registerTool(searchWeb)
```

## What You Can Do
• Search the web
• Send emails
• Query databases
• Control smart home devices

## Common Tools
[Show 2-3 actual tool implementations]

## Learn More
→ [Tool Examples](TOOLS.md)
```

### API Reference Pattern

```markdown
# Agent.input(_:messages:maxIterations:)

Send input to the agent and get a response.

```swift
let response = try await agent.input("Hello")
```

## Parameters
| Name | Type | Description |
|------|------|-------------|
| task | String | User input |
| messages | [Message] | Context (optional) |
| maxIterations | Int? | Override max tool calls |

## Returns
`String` - The agent's response

## Example
[One complete, runnable example]
```

## What to Avoid

### ❌ Theory Before Practice

```markdown
BAD:
"ConnectOnion-Swift leverages Swift's actor model to provide 
thread-safe agent orchestration with automatic reference counting..."

GOOD:
"Create thread-safe agents:"
```swift
let agent = Agent(name: "safe")  // Automatically thread-safe
```
```

### ❌ Multiple Concepts

```markdown
BAD:
"This page covers agents, tools, history, and deployment"

GOOD:
"This page covers agents. For tools, see [Tools](TOOLS.md)"
```

### ❌ Long Examples

```markdown
BAD:
[50 lines of code with complex setup]

GOOD:
[5 lines that work immediately]
[Link to complete example if needed]
```

### ❌ Unexplained Output

```markdown
BAD:
"Run this code to see the output"

GOOD:
"Run this code:"
```swift
print(agent.name)
```
"Output: `assistant`"
```

### ❌ Abstract Examples

```markdown
BAD:
struct AbstractDataProcessor: Tool { ... }

GOOD:
struct EmailSender: Tool { ... }
```

## Mobile-First Writing

Keep lines short:
```markdown
BAD:
This is a very long line that goes on and on and makes it hard to read on mobile devices and small screens.

GOOD:
This is a short line.
It's easy to read on phones.
Each sentence gets its own line.
```

## The "Busy Developer" Test

Imagine a developer who:
- Has 30 seconds to evaluate your framework
- Is comparing 5 different options
- Will close the tab if confused

**Every doc should pass this test.**

## Documentation Types

### 1. Quickstart (2 minutes)
- 3-5 steps max
- Copy-paste code
- Immediate success
- Link to next step

### 2. Guides (5 minutes)
- Single topic
- Progressive examples
- Common patterns
- Troubleshooting

### 3. API Reference (lookup)
- Searchable
- Complete signatures
- One example per method
- Link to guides

### 4. Examples (exploration)
- Complete projects
- Well-commented
- Different complexity levels
- Real use cases

## Remember

> "The best documentation is the code itself. 
> The second best is showing the code in action."

Every doc should make someone think: **"Wow, that's simple!"**

## The Ultimate Test

Can you explain ConnectOnion-Swift to someone in an elevator?

**"It's Swift AI agents in one line:**
```swift
let agent = Agent(name: "bot")
```
**Add tools as functions. It handles the rest."**

If you need more words, simplify the framework.