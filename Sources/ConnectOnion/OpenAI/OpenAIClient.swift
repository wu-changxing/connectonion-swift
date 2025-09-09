import Foundation

public struct OpenAIClient: LLM {
    public struct Config: Sendable {
        public var apiKey: String
        public var model: String
        public var baseURL: URL
        public init(apiKey: String, model: String = "gpt-4o-mini", baseURL: URL = URL(string: "https://api.openai.com/v1")!) {
            self.apiKey = apiKey
            self.model = model
            self.baseURL = baseURL
        }
    }

    public let config: Config
    public protocol HTTPTransport {
        func send(_ request: URLRequest) async throws -> (Data, URLResponse)
    }

    public struct URLSessionTransport: HTTPTransport {
        private let session: URLSession
        public init(session: URLSession = .shared) { self.session = session }
        public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
            try await session.data(for: request)
        }
    }

    private let transport: HTTPTransport

    public init(config: Config, transport: HTTPTransport = URLSessionTransport()) {
        self.config = config
        self.transport = transport
    }

    public func generate(messages: [Message], tools: [ToolSpec]?) async throws -> LLMResponse {
        struct ChatMessage: Encodable { let role: String; let content: String }
        struct ToolFunc: Encodable { let name: String; let description: String; let parameters: JSONValue }
        struct ToolDecl: Encodable { let type: String = "function"; let function: ToolFunc }
        struct Request: Encodable {
            let model: String
            let messages: [ChatMessage]
            let tools: [ToolDecl]?
            let tool_choice: String?
        }
        struct Response: Decodable {
            struct Choice: Decodable {
                struct Msg: Decodable {
                    struct ToolCall: Decodable { struct Func: Decodable { let name: String; let arguments: String }; let type: String; let function: Func }
                    let content: String?
                    let tool_calls: [ToolCall]?
                }
                let message: Msg
            }
            let choices: [Choice]
        }

        let toolDecls: [ToolDecl]? = tools?.map { .init(function: .init(name: $0.name, description: $0.description, parameters: $0.parameters)) }
        let req = Request(
            model: config.model,
            messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) },
            tools: toolDecls,
            tool_choice: toolDecls == nil ? nil : "auto"
        )

        var url = config.baseURL
        url.append(path: "/chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(req)

        let (data, response) = try await transport.send(request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8>"
            throw NSError(domain: "OpenAIClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI error: \(body)"])
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let msg = decoded.choices.first?.message
        let content = msg?.content
        let toolCalls: [LLMToolCall] = (msg?.tool_calls ?? []).compactMap { call in
            guard call.type == "function" else { return nil }
            // arguments is JSON string
            let data = Data(call.function.arguments.utf8)
            let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            let jsonArgs = obj.reduce(into: [String: JSONValue]()) { acc, pair in
                acc[pair.key] = OpenAIClient.anyToJSONValue(pair.value)
            }
            return LLMToolCall(name: call.function.name, arguments: jsonArgs)
        }
        return LLMResponse(content: content, toolCalls: toolCalls)
    }

    static func anyToJSONValue(_ value: Any) -> JSONValue {
        switch value {
        case let v as NSNull: return .null
        case let v as Bool: return .bool(v)
        case let v as NSNumber: return .number(v.doubleValue)
        case let v as String: return .string(v)
        case let v as [Any]: return .array(v.map { anyToJSONValue($0) })
        case let v as [String: Any]:
            var dict: [String: JSONValue] = [:]
            for (k, val) in v { dict[k] = anyToJSONValue(val) }
            return .object(dict)
        default:
            return .string(String(describing: value))
        }
    }
}
