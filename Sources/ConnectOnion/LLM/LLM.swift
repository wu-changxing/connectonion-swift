import Foundation

/// Specification of a tool for LLM function calling.
///
/// Describes a tool's interface in a format compatible with
/// OpenAI's function calling API.
public struct ToolSpec: Codable, Sendable, Equatable {
    public var name: String
    public var description: String
    public var parameters: JSONValue // JSON Schema-like structure

    public init(name: String, description: String, parameters: JSONValue) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

/// Represents a tool call request from the LLM.
///
/// When the LLM decides to use a tool, it returns one or more
/// LLMToolCall instances with the tool name and arguments.
public struct LLMToolCall: Codable, Sendable, Equatable {
    /// Name of the tool to call
    public var name: String
    /// Arguments to pass to the tool
    public var arguments: [String: JSONValue]
}

/// Response from an LLM generation request.
///
/// Contains either text content, tool call requests, or both.
public struct LLMResponse: Codable, Sendable, Equatable {
    /// Text response from the LLM (if any)
    public var content: String?
    /// Tool calls requested by the LLM
    public var toolCalls: [LLMToolCall]
}

/// Protocol for Language Model implementations.
///
/// Defines the interface for interacting with LLMs. Implementations
/// handle the specifics of API communication.
///
/// Example implementation:
/// ```swift
/// struct MyLLM: LLM {
///     func generate(messages: [Message], tools: [ToolSpec]?) async throws -> LLMResponse {
///         // API call implementation
///     }
/// }
/// ```
public protocol LLM: Sendable {
    /// Generates a response from the LLM.
    ///
    /// - Parameters:
    ///   - messages: Conversation history
    ///   - tools: Optional tool specifications for function calling
    /// - Returns: LLM response with content and/or tool calls
    /// - Throws: API or network errors
    func generate(messages: [Message], tools: [ToolSpec]?) async throws -> LLMResponse
}

