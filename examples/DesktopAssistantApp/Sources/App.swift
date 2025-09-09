import SwiftUI
import ConnectOnion
import AppKit

@main
struct DesktopAssistantApp: App {
    @StateObject private var model = AssistantViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 720, minHeight: 520)
        }
    }
}

struct ChatItem: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    var text: String
}

final class AssistantViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var messages: [ChatItem] = []
    @Published var isBusy: Bool = false
    @Published var modelName: String = "gpt-4o-mini"
    @Published var baseHost: String = "api.openai.com"

    private var agent: Agent?
    private var context: [Message] = []
    private var inFlightTask: Task<Void, Never>?

    init() {
        EnvLoader.loadDotEnvIfPresent()
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            let model = ProcessInfo.processInfo.environment["OPENAI_MODEL"] ?? "gpt-4o-mini"
            let baseURLStr = ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1"
            let baseURL = URL(string: baseURLStr) ?? URL(string: "https://api.openai.com/v1")!
            self.modelName = model
            self.baseHost = baseURL.host ?? "api.openai.com"
            let historyDir = URL(fileURLWithPath: "../../.connectonion", isDirectory: true)
            
            // Create agent with simplified initialization and system prompt
            let agent = Agent(
                name: "desktop-assistant-app",
                historyDir: historyDir,
                model: model,
                systemPrompt: "You are a careful desktop assistant. Prefer using the 'shell' tool for CLI tasks. Allowed commands: echo, ls, pwd, date, whoami.",
                apiKey: apiKey
            )
            Task { await agent.registerTool(ShellTool()) }
            self.agent = agent
        } else {
            messages.append(ChatItem(role: .assistant, text: "Missing OPENAI_API_KEY. Add to .env or scheme environment."))
        }
    }

    func send() { quickSend(input) }

    func quickSend(_ text: String) {
        guard let agent else { return }
        let prompt = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        input = ""
        messages.append(ChatItem(role: .user, text: prompt))
        isBusy = true
        inFlightTask?.cancel()
        inFlightTask = Task { @MainActor in
            defer { self.isBusy = false }
            do {
                let reply = try await agent.input(prompt, messages: context)
                self.messages.append(ChatItem(role: .assistant, text: reply))
                self.context.append(Message(role: .user, content: prompt))
                self.context.append(Message(role: .assistant, content: reply))
            } catch is CancellationError {
                self.messages.append(ChatItem(role: .assistant, text: "(Cancelled)"))
            } catch {
                self.messages.append(ChatItem(role: .assistant, text: "Error: \(error.localizedDescription)"))
            }
        }
    }

    func stop() { inFlightTask?.cancel(); isBusy = false }
    func clearChat() {
        messages.removeAll()
        context = []  // System prompt is now managed by the Agent
    }
}

struct ContentView: View {
    @EnvironmentObject var model: AssistantViewModel
    var body: some View {
        VStack(spacing: 10) {
            // Top bar
            HStack(spacing: 12) {
                Label("Model: \(model.modelName)", systemImage: "brain.head.profile").font(.caption)
                Label("Host: \(model.baseHost)", systemImage: "network").font(.caption)
                Spacer()
                Button { withAnimation { model.clearChat() } } label: { Label("Clear", systemImage: "trash") }
                    .keyboardShortcut(.delete, modifiers: [.command])
            }
            .padding(.horizontal, 4)

            // Chat area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(model.messages.enumerated()), id: \.element.id) { _, item in
                            ChatBubble(item: item)
                                .id(item.id)
                        }
                    }.padding(12)
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: model.messages.count) { _ in
                    if let last = model.messages.last?.id { withAnimation { proxy.scrollTo(last, anchor: .bottom) } }
                }
            }

            // Quick actions
            HStack(spacing: 8) {
                Button("List files") { model.quickSend("Use shell to run /bin/ls -la") }
                Button("Who am I") { model.quickSend("Use shell to run /usr/bin/whoami") }
                Button("Time") { model.quickSend("Use shell to run /bin/date") }
                Spacer()
                if model.isBusy { Button(role: .cancel) { model.stop() } label: { Label("Stop", systemImage: "stop.fill") } }
            }

            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                GrowingTextEditor(text: $model.input, minHeight: 36, maxHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                Button(action: { model.send() }) {
                    if model.isBusy { ProgressView() } else { Image(systemName: "paperplane.fill") }
                }
                .help("Send (⌘↩)")
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(model.isBusy)
            }
        }
        .padding(10)
    }
}

struct ChatBubble: View {
    let item: ChatItem
    var isUser: Bool { item.role == .user }
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: isUser ? "person.fill" : "brain.head.profile").foregroundColor(isUser ? .blue : .green)
                    Text(isUser ? "You" : "Assistant").font(.caption).foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    if !isUser {
                        Button(action: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(item.text, forType: .string) }) { Image(systemName: "doc.on.doc") }
                            .buttonStyle(.plain).help("Copy")
                    }
                }
                if isUser {
                    Text(item.text).textSelection(.enabled).frame(maxWidth: 520, alignment: .leading)
                } else {
                    if let attr = try? AttributedString(markdown: item.text) {
                        Text(attr).textSelection(.enabled).frame(maxWidth: 520, alignment: .leading)
                    } else {
                        Text(item.text).textSelection(.enabled).frame(maxWidth: 520, alignment: .leading)
                    }
                }
            }
            .padding(10)
            .background(isUser ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            if !isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

struct GrowingTextEditor: NSViewRepresentable {
    @Binding var text: String
    var minHeight: CGFloat
    var maxHeight: CGFloat
    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.delegate = context.coordinator
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = textView
        scroll.drawsBackground = false
        return scroll
    }
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let tv = nsView.documentView as! NSTextView
        if tv.string != text { tv.string = text }
        let fitting = min(max(tv.intrinsicContentSize.height, minHeight), maxHeight)
        nsView.heightAnchor.constraint(equalToConstant: fitting).isActive = true
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, NSTextViewDelegate { let parent: GrowingTextEditor; init(_ p: GrowingTextEditor) { parent = p }
        func textDidChange(_ notification: Notification) { if let tv = notification.object as? NSTextView { parent.text = tv.string } }
    }
}

struct ShellTool: Tool {
    let name = "shell"
    let summary = "Execute a safe shell command. Allowed: echo, ls, pwd, date, whoami"
    let allowlist: Set<String> = ["/bin/echo", "/bin/ls", "/bin/pwd", "/bin/date", "/usr/bin/whoami"]

    func call(args: [String : JSONValue]) async throws -> JSONValue {
        guard case let .string(cmdPath)? = args["cmd"] else {
            return .object(["error": .string("missing cmd")])
        }
        guard allowlist.contains(cmdPath) else {
            return .object(["error": .string("command not allowed")])
        }
        var proc = Process(); proc.executableURL = URL(fileURLWithPath: cmdPath)
        if case let .array(arr)? = args["args"] {
            proc.arguments = arr.compactMap { if case let .string(s) = $0 { return s } else { return nil } }
        }
        let out = Pipe(); proc.standardOutput = out
        let err = Pipe(); proc.standardError = err
        try proc.run(); proc.waitUntilExit()
        let stdout = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return .object(["status": .number(Double(proc.terminationStatus)), "stdout": .string(stdout), "stderr": .string(stderr)])
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
