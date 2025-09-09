import Foundation

/// A tool implementation that wraps a closure/function for type-safe tool creation.
///
/// FunctionTool provides a simple way to create tools from closures without
/// implementing the full Tool protocol.
///
/// Example:
/// ```swift
/// let tool = FunctionTool(
///     name: "echo",
///     summary: "Echo the input",
///     parameters: .object(["type": .string("object")])
/// ) { args in
///     return .object(["echo": args["text"] ?? .string("")])
/// }
/// ```
public struct FunctionTool: Tool {
    public let name: String
    public let summary: String
    public let parameters: JSONValue
    private let handler: @Sendable ([String: JSONValue]) async throws -> JSONValue
    
    public init(
        name: String,
        summary: String,
        parameters: JSONValue = .object([:]),
        handler: @Sendable @escaping ([String: JSONValue]) async throws -> JSONValue
    ) {
        self.name = name
        self.summary = summary
        self.parameters = parameters
        self.handler = handler
    }
    
    public func call(args: [String: JSONValue]) async throws -> JSONValue {
        return try await handler(args)
    }
}

/// Creates a type-safe tool from a function with Codable parameters and result.
///
/// This function provides compile-time type safety for tool creation by using
/// Codable types for parameters and results.
///
/// Example:
/// ```swift
/// struct SearchParams: Codable {
///     let query: String
///     let limit: Int?
/// }
/// 
/// struct SearchResult: Codable {
///     let items: [String]
/// }
/// 
/// let searchTool = createTool(
///     name: "search",
///     summary: "Search for items",
///     parameterType: SearchParams.self
/// ) { params in
///     // Type-safe implementation
///     return SearchResult(items: ["result1", "result2"])
/// }
/// ```
///
/// - Parameters:
///   - name: Unique identifier for the tool
///   - summary: Description of the tool's function
///   - parameterType: The Codable type for parameters
///   - handler: Async closure that processes parameters and returns results
/// - Returns: A FunctionTool ready to be registered with an agent
public func createTool<T: Codable, R: Codable>(
    name: String,
    summary: String,
    parameterType: T.Type,
    handler: @Sendable @escaping (T) async throws -> R
) -> FunctionTool {
    let parameters = generateJSONSchema(for: T.self)
    
    return FunctionTool(
        name: name,
        summary: summary,
        parameters: parameters
    ) { args in
        // Convert args dictionary to the expected type
        let argsDict = toDictionary(args)
        let jsonData = try JSONSerialization.data(withJSONObject: argsDict)
        let params = try JSONDecoder().decode(T.self, from: jsonData)
        let result = try await handler(params)
        
        // Convert result back to JSONValue
        let resultData = try JSONEncoder().encode(result)
        let resultDict = try JSONSerialization.jsonObject(with: resultData) as? [String: Any] ?? [:]
        return fromAny(resultDict)
    }
}

/// Generates a basic JSON Schema for a Codable type.
///
/// Note: This is a simplified implementation. For production use,
/// consider using reflection or property wrappers for accurate schema generation.
///
/// - Parameter type: The type to generate schema for
/// - Returns: JSONValue representing the schema
private func generateJSONSchema<T>(for type: T.Type) -> JSONValue {
    // This is a simplified schema generator
    // In a real implementation, you'd use Mirror or property wrappers for better introspection
    return .object([
        "type": .string("object"),
        "properties": .object([:])
    ])
}

// MARK: - JSONValue Conversion Helpers

/// Converts a dictionary of JSONValues to native Swift types.
/// - Parameter args: Dictionary with JSONValue values
/// - Returns: Dictionary with Any values
func toDictionary(_ args: [String: JSONValue]) -> [String: Any] {
    return args.mapValues { toAny($0) }
}

/// Converts a JSONValue to its native Swift equivalent.
/// - Parameter value: The JSONValue to convert
/// - Returns: Native Swift type (String, Double, Bool, etc.)
func toAny(_ value: JSONValue) -> Any {
    switch value {
    case .null:
        return NSNull()
    case .bool(let b):
        return b
    case .number(let n):
        return n
    case .string(let s):
        return s
    case .array(let a):
        return a.map { toAny($0) }
    case .object(let o):
        return o.mapValues { toAny($0) }
    }
}

/// Converts a native Swift value to JSONValue.
/// - Parameter any: Native Swift value
/// - Returns: Equivalent JSONValue representation
func fromAny(_ any: Any) -> JSONValue {
    switch any {
    case is NSNull:
        return .null
    case let b as Bool:
        return .bool(b)
    case let n as Int:
        return .number(Double(n))
    case let n as Double:
        return .number(n)
    case let s as String:
        return .string(s)
    case let a as [Any]:
        return .array(a.map { fromAny($0) })
    case let d as [String: Any]:
        return .object(d.mapValues { fromAny($0) })
    default:
        return .null
    }
}