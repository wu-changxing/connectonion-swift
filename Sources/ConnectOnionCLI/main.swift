import Foundation
import ConnectOnion

// Minimal CLI: supports `chat --task "..."` with env OPENAI_API_KEY

@main
struct ConnectOnionCLI {
    static func main() async {
        // Load .env if present (local then parent)
        EnvLoader.loadDotEnvIfPresent()
        let args = CommandLine.arguments.dropFirst()
        guard args.first == "chat" else {
            print("Usage: connectonion-cli chat --task \"...\" [--model <id>] [--data-dir <path>]")
            return
        }
        var task: String?
        var model = ProcessInfo.processInfo.environment["OPENAI_MODEL"] ?? "gpt-4o-mini"
        var dataDir = URL(fileURLWithPath: ".connectonion", isDirectory: true)
        var apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        var baseURL = ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1"

        var idx = args.dropFirst().makeIterator()
        while let token = idx.next() {
            switch token {
            case "--task": task = idx.next()
            case "--model": if let v = idx.next() { model = v }
            case "--data-dir": if let v = idx.next() { dataDir = URL(fileURLWithPath: v, isDirectory: true) }
            case "--api-key": apiKey = idx.next()
            case "--base-url": if let v = idx.next() { baseURL = v }
            default: break
            }
        }

        guard let task else { print("Missing --task"); return }
        guard let apiKey else { print("Missing OPENAI_API_KEY or --api-key"); return }
        guard let base = URL(string: baseURL) else { print("Invalid base URL"); return }

        let client = OpenAIClient(config: .init(apiKey: apiKey, model: model, baseURL: base))
        let agent = Agent(name: "swift", llm: client, historyDir: dataDir, model: model)
        do {
            let output = try await agent.input(task)
            print(output)
        } catch {
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }
}

enum EnvLoader {
    static func loadDotEnvIfPresent() {
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true)
        let candidates = [
            cwd.appending(path: ".env"),
            cwd.appending(path: "../.env")
        ]
        for url in candidates where fm.fileExists(atPath: url.path) {
            if let content = try? String(contentsOf: url) {
                for line in content.split(separator: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                    if let eq = trimmed.firstIndex(of: "=") {
                        let key = String(trimmed[..<eq]).trimmingCharacters(in: .whitespaces)
                        var val = String(trimmed[trimmed.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
                        if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                            val = String(val.dropFirst().dropLast())
                        }
                        setenv(key, val, 0) // do not overwrite existing env
                    }
                }
            }
            break
        }
    }
}
