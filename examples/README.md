# ConnectOnion-Swift Examples

This directory contains example agents built on the ConnectOnion Swift SDK.

- CLIAssistant: A terminal assistant that can execute safe CLI jobs via a shell tool.
- CLITerminalUI: A terminal chat UI (TUI) with a scrollable log and prompt.
- DesktopAssistantApp: A SwiftUI macOS chat app. Open in Xcode to run.

## CLIAssistant

Run:

```
cd connectonion-swift/examples/CLIAssistant
swift run cli-assistant
```

Environment:
- Reads `OPENAI_API_KEY` from `../../.env` or local `.env`.

## DesktopAssistantApp (SwiftUI)

Open in Xcode:

- File > Open > select `connectonion-swift/examples/DesktopAssistantApp/Package.swift`
- Choose the `DesktopAssistantApp` scheme and Run

Notes:
- Requires `OPENAI_API_KEY` in the scheme environment or `.env` alongside the package (already copied).
- This is intended for Xcode; `swift run` won't open a GUI app bundle.
