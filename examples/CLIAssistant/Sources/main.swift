import Foundation
import ConnectOnion

// A safe shell tool with an allowlist to run simple CLI jobs.
struct ShellTool: Tool {
    let name = "shell"
    let summary = "Execute a safe shell command. Allowed: echo, ls, pwd, date, whoami"
    let allowlist: Set<String> = ["/bin/echo", "/bin/ls", "/bin/pwd", "/bin/date", "/usr/bin/whoami"]

    var parameters: JSONValue { .object([
        "type": .string("object"),
        "properties": .object([
            "cmd": .object(["type": .string("string"), "description": .string("Executable path (allowlist only)")]),
            "args": .object(["type": .string("array"), "items": .object(["type": .string("string")])])
        ]),
        "required": .array([.string("cmd")])
    ]) }
    func call(args: [String : JSONValue]) async throws -> JSONValue {
        guard case let .string(cmdPath)? = args["cmd"] else {
            return .object(["error": .string("missing cmd")])
        }
        let cmd = cmdPath
        guard allowlist.contains(cmd) else {
            return .object(["error": .string("command not allowed")])
        }
        var proc = Process()
        proc.executableURL = URL(fileURLWithPath: cmd)
        var arguments: [String] = []
        if case let .array(arr)? = args["args"] {
            arguments = arr.compactMap { if case let .string(s) = $0 { return s } else { return nil } }
        }
        proc.arguments = arguments

        let outPipe = Pipe(); proc.standardOutput = outPipe
        let errPipe = Pipe(); proc.standardError = errPipe

        try proc.run()
        proc.waitUntilExit()
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let status = Int(proc.terminationStatus)
        return .object(["status": .number(Double(status)), "stdout": .string(out), "stderr": .string(err)])
    }
}

struct ListDirTool: Tool {
    let name = "list_dir"
    let summary = "List files under a safe base directory (CONNECTONION_WORKDIR or CWD)."
    let base: URL = {
        let fm = FileManager.default
        if let w = ProcessInfo.processInfo.environment["CONNECTONION_WORKDIR"] { return URL(fileURLWithPath: w, isDirectory: true) }
        return URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true)
    }()
    var parameters: JSONValue { .object([
        "type": .string("object"),
        "properties": .object([
            "path": .object(["type": .string("string"), "description": .string("Relative path under base dir")])
        ]),
        "required": .array([.string("path")])
    ]) }
    func call(args: [String : JSONValue]) async throws -> JSONValue {
        guard case let .string(rel)? = args["path"] else { return .object(["error": .string("missing path")]) }
        let target = base.appending(path: rel)
        let baseStd = base.standardizedFileURL.path
        let tgtStd = target.standardizedFileURL.path
        guard tgtStd.hasPrefix(baseStd) else { return .object(["error": .string("path outside base")]) }
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: tgtStd) else { return .object(["error": .string("cannot list")]) }
        return .object(["files": .array(items.map { .string($0) })])
    }
}

@main
struct CLIAssistantMain {
    static func main() async {
        EnvLoader.loadDotEnvIfPresent()
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fputs("Missing OPENAI_API_KEY. Add to ../../.env or environment.\n", stderr)
            exit(1)
        }
        let model = ProcessInfo.processInfo.environment["OPENAI_MODEL"] ?? "gpt-4o-mini"
        let baseURL = URL(string: ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1")!

        let historyDir = URL(fileURLWithPath: "../../.connectonion", isDirectory: true)
        
        // Create agent with simplified initialization
        let agent = Agent(
            name: "cli-assistant",
            historyDir: historyDir,
            model: model,
            systemPrompt: "You are a careful desktop assistant. Prefer using tools 'shell' and 'list_dir' for CLI tasks. Use only allowed commands: echo, ls, pwd, date, whoami. For browsing files, only operate under the safe base directory.",
            apiKey: apiKey
        )
        await agent.registerTool(ShellTool())
        await agent.registerTool(ListDirTool())

        print("🤖 Desktop CLI Assistant. Type 'exit' to quit.")
        print("Tips: Ask me to list files, print date, or echo text.")

        var context: [Message] = []

        while true {
            fputs("You> ", stdout)
            guard let raw = readLine() else { break }
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            if line == "exit" || line == "/quit" { break }
            if line == "/clear" { print("\u{001B}[2J\u{001B}[H", terminator: ""); continue }
            if line == "/help" {
                print("Commands: /help /clear /quit\nTools: shell(list_dir) — use tool calls by asking naturally (e.g., 'list files under .').")
                continue
            }
            do {
                let reply = try await agent.input(line, messages: context)
                print("Assistant> \(reply)")
                context.append(Message(role: .user, content: line))
                context.append(Message(role: .assistant, content: reply))
            } catch {
                fputs("Error: \(error)\n", stderr)
            }
        }
        print("👋 Bye!")
    }
}

enum EnvLoader {
    static func loadDotEnvIfPresent() {
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true)
        let candidates = [
            cwd.appending(path: ".env"),
            cwd.appending(path: "../../.env")
        ]
        for url in candidates where fm.fileExists(atPath: url.path) {
            if let content = try? String(contentsOf: url) {
                for raw in content.split(separator: "\n") {
                    let line = raw.trimmingCharacters(in: .whitespaces)
                    if line.isEmpty || line.hasPrefix("#") { continue }
                    if let eq = line.firstIndex(of: "=") {
                        let key = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
                        var val = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
                        if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                            val = String(val.dropFirst().dropLast())
                        }
                        setenv(key, val, 0)
                    }
                }
            }
            break
        }
    }
}
