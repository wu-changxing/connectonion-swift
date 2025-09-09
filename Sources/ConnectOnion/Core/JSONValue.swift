import Foundation

/// Type-safe representation of JSON values.
///
/// JSONValue provides a Swift-native way to work with dynamic JSON data
/// while maintaining type safety and Codable compliance.
///
/// Example usage:
/// ```swift
/// let json: JSONValue = .object([
///     "name": .string("Alice"),
///     "age": .number(30),
///     "active": .bool(true),
///     "tags": .array([.string("swift"), .string("ai")])
/// ])
/// ```
public enum JSONValue: Codable, Equatable, Sendable {
    /// Represents JSON null
    case null
    /// Represents a JSON boolean
    case bool(Bool)
    /// Represents a JSON number (integer or floating-point)
    case number(Double)
    /// Represents a JSON string
    case string(String)
    /// Represents a JSON array
    case array([JSONValue])
    /// Represents a JSON object (dictionary)
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let b = try? container.decode(Bool.self) { self = .bool(b); return }
        if let n = try? container.decode(Double.self) { self = .number(n); return }
        if let s = try? container.decode(String.self) { self = .string(s); return }
        if let a = try? container.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? container.decode([String: JSONValue].self) { self = .object(o); return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let b): try container.encode(b)
        case .number(let d): try container.encode(d)
        case .string(let s): try container.encode(s)
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        }
    }
}

