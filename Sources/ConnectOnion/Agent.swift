import Foundation

/// The main orchestrator for AI agent interactions.
/// 
/// `Agent` manages the conversation flow between users and LLMs, handles tool execution,
/// tracks behavior history, and maintains conversation context.
///
/// Example usage:
/// ```swift
/// let agent = Agent(
///     name: "assistant",
///     systemPrompt: "You are a helpful assistant.",
///     apiKey: "your-api-key"
/// )
/// 
/// let response = try await agent.input("Hello!")
/// ```
public actor Agent {
    /// Unique identifier for this agent, used for history tracking
    public let name: String
    
    /// The LLM backend used for generating responses
    private let llm: LLM
    
    /// Storage system for behavior tracking and history
    private let history: HistoryStore
    
    /// The model identifier (e.g., "gpt-4o-mini")
    public var model: String
    
    /// Registry of available tools the agent can use
    private var tools = ToolRegistry()
    
    /// Maximum number of tool-calling iterations per input (default: 10)
    public var maxSteps: Int = 10
    
    /// Optional system prompt to guide the agent's behavior
    public var systemPrompt: String?

    /// Creates a new agent with the specified configuration.
    ///
    /// - Parameters:
    ///   - name: Unique identifier for the agent
    ///   - llm: Optional LLM instance (if nil, creates one using model and apiKey)
    ///   - historyDir: Directory for storing behavior history (default: .connectonion)
    ///   - model: LLM model to use (default: gpt-4o-mini)
    ///   - systemPrompt: Optional system instructions for the agent
    ///   - maxIterations: Maximum tool-calling rounds per input (default: 10)
    ///   - apiKey: API key for LLM service (uses environment if nil)
    public init(
        name: String,
        llm: LLM? = nil,
        historyDir: URL = URL(fileURLWithPath: ".connectonion", isDirectory: true),
        model: String = "gpt-4o-mini",
        systemPrompt: String? = nil,
        maxIterations: Int = 10,
        apiKey: String? = nil
    ) {
        self.name = name
        self.llm = llm ?? createLLM(model: model, apiKey: apiKey)
        self.history = HistoryStore(baseDir: historyDir)
        self.model = model
        self.systemPrompt = systemPrompt
        self.maxSteps = maxIterations
    }

    /// Registers a single tool for the agent to use.
    ///
    /// - Parameter tool: The tool to register
    public func registerTool(_ tool: some Tool) {
        tools.register(tool)
    }
    
    /// Registers multiple tools at once.
    ///
    /// - Parameter toolsList: Array of tools to register
    public func registerTools(_ toolsList: [any Tool]) {
        for tool in toolsList {
            tools.register(tool)
        }
    }

    /// Processes user input and returns the agent's response.
    ///
    /// This method handles the complete interaction cycle including:
    /// - Adding system prompt if configured
    /// - Sending messages to the LLM
    /// - Executing any requested tool calls
    /// - Tracking behavior history
    ///
    /// - Parameters:
    ///   - task: The user's input or question
    ///   - messages: Optional conversation history for context
    ///   - maxIterations: Override for maximum tool-calling rounds
    /// - Returns: The agent's response as a string
    /// - Throws: Errors from LLM or tool execution
    public func input(_ task: String, messages: [Message] = [], maxIterations: Int? = nil) async throws -> String {
        var convo = messages
        
        // Add system prompt if not already present and we have one
        if let systemPrompt = systemPrompt, !messages.contains(where: { $0.role == .system }) {
            convo.insert(Message(role: .system, content: systemPrompt), at: 0)
        }
        
        convo.append(Message(role: .user, content: task))
        var collectedToolCalls: [ToolCall] = []
        
        let iterations = maxIterations ?? maxSteps

        for _ in 0..<iterations {
            let response = try await llm.generate(messages: convo, tools: tools.specList())
            // Execute tool calls if any
            if !response.toolCalls.isEmpty {
                for call in response.toolCalls {
                    guard let tool = tools.get(call.name) else { continue }
                    let started = Date()
                    let result = try await tool.call(args: call.arguments)
                    let dur = Int(Date().timeIntervalSince(started) * 1000.0)
                    collectedToolCalls.append(ToolCall(name: call.name, args: call.arguments, result: result, timingMS: dur))
                    // Feed tool result back into conversation
                    let resultString: String
                    if let data = try? JSONEncoder().encode(result), let s = String(data: data, encoding: .utf8) { resultString = s } else { resultString = "{}" }
                    convo.append(Message(role: .tool, content: resultString))
                }
                continue
            }
            // If model responded with content, return it
            if let content = response.content {
                let assistantMsg = Message(role: .assistant, content: content)
                let record = BehaviorRecord(agent: name, task: task, messages: convo + [assistantMsg], toolCalls: collectedToolCalls, metadata: ["model": .string(model)])
                try await history.append(agentName: name, record: record)
                return content
            }
        }
        // Fallback if no content produced
        let record = BehaviorRecord(agent: name, task: task, messages: convo, toolCalls: collectedToolCalls, metadata: ["model": .string(model)])
        try await history.append(agentName: name, record: record)
        return ""
    }
}
