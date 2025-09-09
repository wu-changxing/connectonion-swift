import XCTest
@testable import ConnectOnion

final class OpenAITests: XCTestCase {
    actor CaptureTransport: OpenAIClient.HTTPTransport {
        var lastBody: Data?
        var statusCode: Int = 200
        var responseJSON: String = "{\"choices\":[{\"message\":{\"content\":\"ok\"}}]}"
        func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
            lastBody = request.httpBody
            let data = Data(responseJSON.utf8)
            let url = request.url ?? URL(string: "https://example.com")!
            let resp = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (data, resp)
        }
    }

    func testBuildsFunctionCallRequest() async throws {
        let transport = CaptureTransport()
        let client = OpenAIClient(config: .init(apiKey: "test"), transport: transport)
        let messages = [Message(role: .user, content: "hi")]
        let tools = [ToolSpec(name: "echo", description: "Echo text", parameters: .object([:]))]
        _ = try await client.generate(messages: messages, tools: tools)
        let body = await transport.lastBody
        XCTAssertNotNil(body)
        let json = try JSONSerialization.jsonObject(with: body!) as? [String: Any]
        XCTAssertEqual(json?["model"] as? String, "gpt-4o-mini")
        let toolArray = json?["tools"] as? [Any]
        XCTAssertEqual((toolArray?.count ?? 0), 1)
        if let first = toolArray?.first as? [String: Any],
           let function = first["function"] as? [String: Any] {
            XCTAssertEqual(function["name"] as? String, "echo")
        } else {
            XCTFail("tools not encoded correctly")
        }
    }
}
