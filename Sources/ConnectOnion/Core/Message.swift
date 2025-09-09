import Foundation

/// Represents the role of a message sender in a conversation.
///
/// Used to distinguish between different participants in the conversation:
/// - `system`: System instructions that guide the agent's behavior
/// - `user`: Input from the human user
/// - `assistant`: Responses from the AI assistant
/// - `tool`: Results from tool executions
public enum Role: String, Codable, Sendable {
    case system
    case user
    case assistant
    case tool
}

/// Represents a single message in a conversation.
///
/// Messages form the conversation history that provides context
/// for the LLM to generate appropriate responses.
///
/// Example:
/// ```swift
/// let userMessage = Message(role: .user, content: "Hello!")
/// let assistantMessage = Message(role: .assistant, content: "Hi there!")
/// let systemMessage = Message(role: .system, content: "You are helpful.")
/// ```
public struct Message: Codable, Equatable, Sendable {
    /// The role of the message sender
    public var role: Role
    
    /// The text content of the message
    public var content: String

    /// Creates a new message with the specified role and content.
    ///
    /// - Parameters:
    ///   - role: The sender's role
    ///   - content: The message text
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

