import Foundation
import ConnectOnion

struct ShellTool: Tool {
    let name = "shell"
    let summary = "Execute a safe shell command. Allowed: echo, ls, pwd, date, whoami"
    let allowlist: Set<String> = ["/bin/echo", "/bin/ls", "/bin/pwd", "/bin/date", "/usr/bin/whoami"]
    var parameters: JSONValue { .object([
        "type": .string("object"),
        "properties": .object([
            "cmd": .object(["type": .string("string")]),
            "args": .object(["type": .string("array"), "items": .object(["type": .string("string")])])
        ]),
        "required": .array([.string("cmd")])
    ]) }
    func call(args: [String : JSONValue]) async throws -> JSONValue {
        guard case let .string(cmdPath)? = args["cmd"] else { return .object(["error": .string("missing cmd")]) }
        guard allowlist.contains(cmdPath) else { return .object(["error": .string("command not allowed")]) }
        var p = Process(); p.executableURL = URL(fileURLWithPath: cmdPath)
        if case let .array(arr)? = args["args"] {
            p.arguments = arr.compactMap { if case let .string(s) = $0 { return s } else { return nil } }
        }
        let out = Pipe(); let err = Pipe(); p.standardOutput = out; p.standardError = err
        try p.run(); p.waitUntilExit()
        let stdout = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return .object(["status": .number(Double(p.terminationStatus)), "stdout": .string(stdout), "stderr": .string(stderr)])
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
            "path": .object(["type": .string("string")])
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
struct TUIMain {
    static func main() async {
        EnvLoader.loadDotEnvIfPresent()
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fputs("Missing OPENAI_API_KEY in ../../.env or .env\n", stderr)
            exit(1)
        }
        let model = ProcessInfo.processInfo.environment["OPENAI_MODEL"] ?? "gpt-4o-mini"
        let historyDir = URL(fileURLWithPath: "../../.connectonion", isDirectory: true)
        
        // Create agent with simplified initialization and system prompt
        let agent = Agent(
            name: "cli-tui",
            historyDir: historyDir,
            model: model,
            systemPrompt: "You are a careful desktop assistant. Prefer using 'shell' tool for CLI tasks. Use allowed commands only: echo, ls, pwd, date, whoami.",
            apiKey: apiKey
        )
        await agent.registerTools([ShellTool(), ListDirTool()])

        var log: [String] = []
        var context: [Message] = []

        func clear() { print("\u{001B}[2J\u{001B}[H", terminator: "") }
        func draw() {
            clear()
            print("CLI Assistant (TUI) — model: \(model)")
            print(String(repeating: "═", count: 80))
            let last = log.suffix(18)
            for line in last { print(line) }
            print(String(repeating: "─", count: 80))
            print("Type your request. Commands: /help /tools /clear /quit")
            print("> ", terminator: "")
            fflush(stdout)
        }

        while true {
            draw()
            guard let line = readLine() else { break }
            if line == "/quit" || line == "exit" { break }
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            if line == "/clear" { log.removeAll(); continue }
            if line == "/help" { log.append("Help> Ask naturally. Tools: shell, list_dir."); continue }
            if line == "/tools" { log.append("Tools> shell(cmd,args), list_dir(path)"); continue }
            log.append("You> \(line)")
            draw()
            do {
                let reply = try await agent.input(line, messages: context)
                log.append("Assistant> \(reply)")
                context.append(Message(role: .user, content: line))
                context.append(Message(role: .assistant, content: reply))
            } catch {
                log.append("Error> \(error.localizedDescription)")
            }
        }
        clear(); print("Goodbye!")
    }
}

enum EnvLoader {
    static func loadDotEnvIfPresent() {
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true)
        let candidates = [cwd.appending(path: ".env"), cwd.appending(path: "../../.env")]
        for url in candidates where fm.fileExists(atPath: url.path) {
            if let content = try? String(contentsOf: url) {
                for raw in content.split(separator: "\n") {
                    let line = raw.trimmingCharacters(in: .whitespaces)
                    if line.isEmpty || line.hasPrefix("#") { continue }
                    if let eq = line.firstIndex(of: "=") {
                        let key = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
                        var val = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
                        if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) { val = String(val.dropFirst().dropLast()) }
                        setenv(key, val, 0)
                    }
                }
            }
            break
        }
    }
}
