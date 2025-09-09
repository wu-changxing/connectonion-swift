import Foundation

/// Protocol defining a tool that agents can use to perform actions.
///
/// Tools extend agent capabilities by providing specific functions that can be
/// called during conversations. The agent decides when to use tools based on
/// the conversation context.
///
/// Example implementation:
/// ```swift
/// struct CalculatorTool: Tool {
///     let name = "calculator"
///     let summary = "Perform math operations"
///     
///     func call(args: [String: JSONValue]) async throws -> JSONValue {
///         // Implementation
///     }
/// }
/// ```
public protocol Tool: Sendable {
    /// Unique identifier for the tool
    var name: String { get }
    
    /// Brief description of what the tool does
    var summary: String { get }
    
    /// Executes the tool with the provided arguments
    /// - Parameter args: Dictionary of arguments passed by the LLM
    /// - Returns: Result as JSONValue
    /// - Throws: Any errors during execution
    func call(args: [String: JSONValue]) async throws -> JSONValue
    
    /// JSON Schema describing the expected parameters (optional)
    var parameters: JSONValue { get }
}

/// Record of a tool invocation including arguments, results, and timing.
///
/// Used for behavior tracking and debugging tool executions.
public struct ToolCall: Codable, Equatable, Sendable {
    public var name: String
    public var args: [String: JSONValue]
    public var result: JSONValue?
    public var timingMS: Int?

    public init(name: String, args: [String: JSONValue], result: JSONValue? = nil, timingMS: Int? = nil) {
        self.name = name
        self.args = args
        self.result = result
        self.timingMS = timingMS
    }
}

/// Registry for managing available tools in an agent.
///
/// Maintains a mapping of tool names to tool instances and provides
/// methods for registration and specification generation.
public struct ToolRegistry: Sendable {
    private var map: [String: any Tool] = [:]
    public init() {}
    /// Registers a tool in the registry.
    /// - Parameter tool: The tool to register
    public mutating func register(_ tool: some Tool) {
        map[tool.name] = tool
    }
    /// Returns specifications for all registered tools.
    /// - Returns: Array of ToolSpec for LLM function calling
    public func specList() -> [ToolSpec] {
        map.values.map { tool in
            ToolSpec(name: tool.name, description: tool.summary, parameters: tool.parameters)
        }
    }
    /// Retrieves a tool by name.
    /// - Parameter name: The tool's name
    /// - Returns: The tool if found, nil otherwise
    public func get(_ name: String) -> (any Tool)? { map[name] }
}

public extension Tool {
    var parameters: JSONValue { .object([:]) }
}
