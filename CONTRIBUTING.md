# Contributing to ConnectOnion-Swift

Thank you for your interest in contributing! We love contributions from the community.

## Quick Start

1. **Fork & Clone**
   ```bash
   git clone https://github.com/yourusername/connectonion-swift.git
   cd connectonion-swift
   ```

2. **Create Branch**
   ```bash
   git checkout -b feature/your-feature
   ```

3. **Make Changes & Test**
   ```bash
   swift test
   ```

4. **Submit PR**
   - Clear description
   - Link any issues
   - Show examples if applicable

## What We're Looking For

### ✅ Great Contributions

- **New Tools** - Useful tools that others can use
- **Examples** - Real-world usage examples
- **Bug Fixes** - With tests
- **Documentation** - Clear, following our style
- **Performance** - Measurable improvements

### 🎯 Especially Wanted

- Tools for popular APIs (Slack, Discord, GitHub, etc.)
- Database integrations
- Web framework integrations (Vapor, Hummingbird)
- Platform support (Linux, Windows via Swift)
- Localization

## Code Guidelines

### Follow Swift Best Practices

```swift
// ✅ GOOD: Clear, simple, Swift-like
struct EmailTool: Tool {
    let name = "send_email"
    let summary = "Send an email"
    
    func call(args: [String: JSONValue]) async throws -> JSONValue {
        // Implementation
    }
}

// ❌ BAD: Over-engineered
class AbstractEmailToolFactoryManager: NSObject, ToolProtocol {
    // Don't do this
}
```

### Keep It Simple

```swift
// ✅ GOOD: Direct and clear
func searchWeb(query: String) -> String {
    return "Results for: \(query)"
}

// ❌ BAD: Unnecessary complexity
func searchWeb<T: StringProtocol>(
    query: T,
    options: SearchOptions = .default,
    completion: @escaping (Result<String, Error>) -> Void
) where T.Element == Character {
    // Too complex for simple task
}
```

### Write Tests

```swift
func testToolExecution() async throws {
    let tool = CalculatorTool()
    let result = try await tool.call(args: [
        "operation": .string("add"),
        "a": .number(2),
        "b": .number(3)
    ])
    
    XCTAssertEqual(result, .object(["result": .number(5)]))
}
```

## Documentation Style

### Follow "Show, Don't Tell"

```markdown
✅ GOOD:
```swift
let agent = Agent(name: "bot")
let response = try await agent.input("Hello")
// Output: "Hi there!"
```

❌ BAD:
"The Agent class provides an abstraction layer..."
```

### Keep Examples Short

```markdown
✅ GOOD: 5-line working example
❌ BAD: 50-line complex setup
```

## Testing Requirements

### All Code Must Have Tests

```swift
// For every new feature, add tests:
// Tests/ConnectOnionTests/YourFeatureTests.swift

final class YourFeatureTests: XCTestCase {
    func testBasicFunctionality() async throws {
        // Test the happy path
    }
    
    func testErrorHandling() async throws {
        // Test error cases
    }
}
```

### Run Tests Before Submitting

```bash
# Run all tests
swift test

# Run specific test
swift test --filter YourFeatureTests
```

## Pull Request Process

### 1. Before You Submit

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] New tests for new features
- [ ] Documentation updated
- [ ] Examples work

### 2. PR Description Template

```markdown
## Summary
Brief description of changes

## Motivation
Why is this needed?

## Changes
- Change 1
- Change 2

## Testing
How to test this

## Examples
```swift
// Show usage
```
```

### 3. Review Process

1. **Automated checks** run first
2. **Community review** - anyone can comment
3. **Maintainer review** - final approval
4. **Merge** - usually within 48 hours

## Adding a New Tool

### 1. Create the Tool

```swift
// Sources/ConnectOnion/Tools/YourTool.swift

public struct YourTool: Tool {
    public let name = "your_tool"
    public let summary = "What it does"
    
    public init() {}  // Must be public
    
    public func call(args: [String: JSONValue]) async throws -> JSONValue {
        // Implementation
    }
}
```

### 2. Add Tests

```swift
// Tests/ConnectOnionTests/Tools/YourToolTests.swift

final class YourToolTests: XCTestCase {
    func testYourTool() async throws {
        let tool = YourTool()
        // Test it
    }
}
```

### 3. Add Example

```swift
// examples/YourToolExample/main.swift

import ConnectOnion

let agent = Agent(name: "example")
await agent.registerTool(YourTool())
// Show it in action
```

### 4. Document It

Add to `docs/TOOLS.md`:
```markdown
## YourTool

Brief description.

```swift
let tool = YourTool()
await agent.registerTool(tool)
```

**Use Cases:**
- Use case 1
- Use case 2
```

## Performance Guidelines

### Measure First

```swift
// Before optimizing, measure:
func testPerformance() throws {
    measure {
        // Code to measure
    }
}
```

### Async All The Way

```swift
// ✅ GOOD: Async/await
func fetchData() async throws -> Data

// ❌ BAD: Callbacks
func fetchData(completion: (Data?) -> Void)
```

## Platform Support

### macOS First

Primary platform is macOS 13+. Ensure all changes work on macOS.

### Linux Compatibility

Nice to have. Mark Linux-specific code:
```swift
#if os(Linux)
    // Linux-specific implementation
#endif
```

## Communication

### Where to Get Help

- **GitHub Issues** - Bug reports, feature requests
- **GitHub Discussions** - Questions, ideas
- **Pull Request** - Code contributions

### Be Respectful

- Constructive feedback only
- Help newcomers
- Assume good intentions
- Celebrate contributions

## Recognition

### Contributors

All contributors are recognized in:
- Release notes
- Contributors file
- GitHub insights

### Special Thanks

Major contributors may be invited to:
- Join maintainer team
- Guide project direction
- Mentor new contributors

## Development Setup

### Prerequisites

- macOS 13+ or Linux (Ubuntu 22.04+)
- Swift 5.9+
- Xcode 15+ (macOS only)

### Environment Setup

```bash
# Clone
git clone https://github.com/wu-changxing/connectonion-swift.git
cd connectonion-swift

# Setup environment
cp .env.example .env
# Add your OPENAI_API_KEY to .env

# Build
swift build

# Test
swift test

# Run example
cd examples/CLIAssistant
swift run
```

### Recommended Tools

- **SwiftLint** - Code style
- **SwiftFormat** - Auto-formatting
- **SourceDocs** - Documentation generation

## Release Process

### Version Numbering

We use semantic versioning: `MAJOR.MINOR.PATCH`

- **PATCH**: Bug fixes, small improvements
- **MINOR**: New features, backward compatible
- **MAJOR**: Breaking changes

### Release Checklist

1. Update version in appropriate files
2. Update CHANGELOG.md
3. Run full test suite
4. Test all examples
5. Update documentation
6. Create git tag
7. Create GitHub release

## Legal

### License

By contributing, you agree that your contributions will be licensed under the MIT License.

### Code of Conduct

Be excellent to each other. Harassment, discrimination, or inappropriate behavior will not be tolerated.

## Thank You!

Every contribution matters, from fixing typos to adding major features. Thank you for making ConnectOnion-Swift better!

## Quick Contribution Ideas

Need inspiration? Here are some quick wins:

### 15-Minute Contributions
- Fix a typo in documentation
- Add a code comment
- Improve an error message
- Add a simple test

### 1-Hour Contributions
- Add a simple tool (like a dice roller)
- Write an example
- Improve README
- Add GitHub Action

### Weekend Projects
- Add a complex tool (database, API integration)
- Create a tutorial
- Build a demo app
- Performance optimization

Start small, we're here to help! 🚀