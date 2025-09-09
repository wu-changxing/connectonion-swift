import XCTest
@testable import ConnectOnion

final class FunctionToolTests: XCTestCase {
    
    func testFunctionToolCreation() async throws {
        let tool = FunctionTool(
            name: "test_tool",
            summary: "A test tool",
            parameters: .object(["type": .string("object")])
        ) { args in
            return .object(["result": .string("success")])
        }
        
        XCTAssertEqual(tool.name, "test_tool")
        XCTAssertEqual(tool.summary, "A test tool")
        
        let result = try await tool.call(args: [:])
        XCTAssertEqual(result, .object(["result": .string("success")]))
    }
    
    func testFunctionToolWithParameters() async throws {
        let tool = FunctionTool(
            name: "echo",
            summary: "Echo the input",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "message": .object(["type": .string("string")])
                ])
            ])
        ) { args in
            guard case let .string(msg)? = args["message"] else {
                return .object(["error": .string("missing message")])
            }
            return .object(["echo": .string(msg)])
        }
        
        let result = try await tool.call(args: ["message": .string("Hello")])
        XCTAssertEqual(result, .object(["echo": .string("Hello")]))
    }
    
    func testCreateToolWithTypedParameters() async throws {
        struct EchoParams: Codable {
            let message: String
            let repeatCount: Int?
        }
        
        struct EchoResult: Codable {
            let output: String
        }
        
        let tool = createTool(
            name: "typed_echo",
            summary: "Echo with typed parameters",
            parameterType: EchoParams.self
        ) { (params: EchoParams) -> EchoResult in
            let count = params.repeatCount ?? 1
            let output = Array(repeating: params.message, count: count).joined(separator: " ")
            return EchoResult(output: output)
        }
        
        XCTAssertEqual(tool.name, "typed_echo")
        XCTAssertEqual(tool.summary, "Echo with typed parameters")
        
        // Test with repeatCount parameter
        let result1 = try await tool.call(args: [
            "message": .string("Hi"),
            "repeatCount": .number(3)
        ])
        
        // Verify the structure of the result
        if case let .object(dict) = result1,
           case let .string(output) = dict["output"] {
            XCTAssertEqual(output, "Hi Hi Hi")
        } else {
            XCTFail("Unexpected result structure")
        }
    }
    
    func testJSONValueConversions() {
        // Test toDictionary
        let jsonDict: [String: JSONValue] = [
            "string": .string("test"),
            "number": .number(42),
            "bool": .bool(true),
            "null": .null,
            "array": .array([.string("a"), .string("b")]),
            "object": .object(["nested": .string("value")])
        ]
        
        let dict = toDictionary(jsonDict)
        XCTAssertEqual(dict["string"] as? String, "test")
        XCTAssertEqual(dict["number"] as? Double, 42)
        XCTAssertEqual(dict["bool"] as? Bool, true)
        XCTAssertTrue(dict["null"] is NSNull)
        
        // Test fromAny
        let any: [String: Any] = [
            "string": "test",
            "number": 42.0,
            "bool": true,
            "null": NSNull(),
            "array": ["a", "b"],
            "object": ["nested": "value"]
        ]
        
        let jsonValue = fromAny(any)
        XCTAssertEqual(jsonValue, .object([
            "string": .string("test"),
            "number": .number(42.0),
            "bool": .bool(true),
            "null": .null,
            "array": .array([.string("a"), .string("b")]),
            "object": .object(["nested": .string("value")])
        ]))
    }
    
    func testToAnyConversion() {
        XCTAssertEqual(toAny(.string("test")) as? String, "test")
        XCTAssertEqual(toAny(.number(42)) as? Double, 42)
        XCTAssertEqual(toAny(.bool(true)) as? Bool, true)
        XCTAssertTrue(toAny(.null) is NSNull)
        
        let arrayResult = toAny(.array([.string("a"), .number(1)]))
        if let array = arrayResult as? [Any] {
            XCTAssertEqual(array[0] as? String, "a")
            XCTAssertEqual(array[1] as? Double, 1)
        } else {
            XCTFail("Array conversion failed")
        }
    }
}