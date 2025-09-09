import Foundation

/// Factory function to create appropriate LLM based on model string
public func createLLM(model: String = "gpt-4o-mini", apiKey: String? = nil, baseURL: URL? = nil) -> LLM {
    // For now, all models go through OpenAI-compatible API
    // In the future, this could route to Claude, Gemini, etc. based on model prefix
    
    let actualKey = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    let actualBaseURL = baseURL ?? URL(string: ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1")!
    
    let config = OpenAIClient.Config(
        apiKey: actualKey,
        model: model,
        baseURL: actualBaseURL
    )
    
    return OpenAIClient(config: config)
}

/// Helper to load environment variables from .env file
public func loadEnvironment(from path: String = ".env") {
    let fm = FileManager.default
    let url = URL(fileURLWithPath: path)
    
    guard fm.fileExists(atPath: url.path),
          let content = try? String(contentsOf: url) else {
        return
    }
    
    for line in content.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
        
        if let equalIndex = trimmed.firstIndex(of: "=") {
            let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
            var value = String(trimmed[trimmed.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)
            
            // Remove quotes if present
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || 
               (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            
            setenv(key, value, 0)
        }
    }
}