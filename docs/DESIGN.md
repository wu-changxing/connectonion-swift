# Design Overview

ConnectOnion Swift mirrors the Python framework with a small, protocol-first core and explicit separation between core logic, LLM integration, persistence, and CLI.

## Modules (SPM targets/files)

- Core: `Agent`, `Tool`, `ToolCall`, `Message`
- LLM: `LLM` protocol, `LLMResponse`, adapters
- OpenAI: `OpenAIClient` for chat + function calling
- History: codable history records and persistence
- Tracing: simple step timing and breadcrumbs
- CLI: `connectonion-cli` entrypoint

## Key Principles

- Protocol-driven design for testability (mockable LLM and storage)
- Async/await APIs
- Pure value models (Codable) for interchange and history
- Provider-agnostic `LLM` protocol; OpenAI as first implementation
- Minimal shared global state; explicit injection

## Data Paths

- Default repository-local: `./.connectonion/agents/{name}/behavior.json`
- Override via flag `--data-dir` or env `CONNECTONION_DATA_DIR`
- Consider macOS path `~/Library/Application Support/ConnectOnion` for distribution builds

## Compatibility with Python

History JSON mirrors Python’s schema to enable replay and analysis across implementations. See `HISTORY_SCHEMA.md`.

