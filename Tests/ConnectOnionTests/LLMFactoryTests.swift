import XCTest
@testable import ConnectOnion

final class LLMFactoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear environment variables for clean tests
        unsetenv("OPENAI_API_KEY")
        unsetenv("OPENAI_BASE_URL")
        unsetenv("OPENAI_MODEL")
    }
    
    func testCreateLLMWithDefaults() {
        let llm = createLLM()
        XCTAssertNotNil(llm)
        // Check that it creates an OpenAIClient
        XCTAssertTrue(llm is OpenAIClient)
    }
    
    func testCreateLLMWithCustomParameters() {
        let llm = createLLM(
            model: "gpt-4",
            apiKey: "test-key",
            baseURL: URL(string: "https://custom.api.com/v1")
        )
        XCTAssertNotNil(llm)
        XCTAssertTrue(llm is OpenAIClient)
    }
    
    func testCreateLLMWithEnvironmentVariables() {
        setenv("OPENAI_API_KEY", "env-test-key", 1)
        setenv("OPENAI_BASE_URL", "https://env.api.com/v1", 1)
        
        let llm = createLLM(model: "gpt-3.5-turbo")
        XCTAssertNotNil(llm)
        XCTAssertTrue(llm is OpenAIClient)
        
        // Clean up
        unsetenv("OPENAI_API_KEY")
        unsetenv("OPENAI_BASE_URL")
    }
    
    func testLoadEnvironmentFromFile() {
        // Create a temporary .env file
        let tempDir = FileManager.default.temporaryDirectory
        let envFile = tempDir.appendingPathComponent("test.env")
        
        let envContent = """
        # Test environment file
        TEST_API_KEY=test-key-123
        TEST_MODEL="gpt-4"
        TEST_URL='https://test.api.com'
        EMPTY_VALUE=
        """
        
        do {
            try envContent.write(to: envFile, atomically: true, encoding: .utf8)
            
            // Load the environment
            loadEnvironment(from: envFile.path)
            
            // Verify environment variables were set
            XCTAssertEqual(ProcessInfo.processInfo.environment["TEST_API_KEY"], "test-key-123")
            XCTAssertEqual(ProcessInfo.processInfo.environment["TEST_MODEL"], "gpt-4")
            XCTAssertEqual(ProcessInfo.processInfo.environment["TEST_URL"], "https://test.api.com")
            XCTAssertEqual(ProcessInfo.processInfo.environment["EMPTY_VALUE"], "")
            
            // Clean up
            try FileManager.default.removeItem(at: envFile)
            unsetenv("TEST_API_KEY")
            unsetenv("TEST_MODEL")
            unsetenv("TEST_URL")
            unsetenv("EMPTY_VALUE")
        } catch {
            XCTFail("Failed to test environment loading: \(error)")
        }
    }
    
    func testLoadEnvironmentIgnoresComments() {
        let tempDir = FileManager.default.temporaryDirectory
        let envFile = tempDir.appendingPathComponent("test-comments.env")
        
        let envContent = """
        # This is a comment
        VALID_KEY=valid_value
        # Another comment
        # COMMENTED_KEY=should_not_load
        """
        
        do {
            try envContent.write(to: envFile, atomically: true, encoding: .utf8)
            
            loadEnvironment(from: envFile.path)
            
            XCTAssertEqual(ProcessInfo.processInfo.environment["VALID_KEY"], "valid_value")
            XCTAssertNil(ProcessInfo.processInfo.environment["COMMENTED_KEY"])
            
            // Clean up
            try FileManager.default.removeItem(at: envFile)
            unsetenv("VALID_KEY")
        } catch {
            XCTFail("Failed to test comment handling: \(error)")
        }
    }
    
    func testLoadEnvironmentHandlesMissingFile() {
        // This should not crash or throw
        loadEnvironment(from: "/non/existent/path/.env")
        // If we reach here, the test passes
        XCTAssertTrue(true)
    }
}