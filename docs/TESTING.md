# Testing Strategy

We follow TDD where possible:

1. Tests for core models and serialization
2. Tests for LLM protocol and OpenAI request building (with mock transport)
3. Tests for tool registry and invocation
4. Tests for Agent loop and tracing
5. Tests for history persistence roundtrip

Mocks:

- `MockLLM`: returns deterministic `LLMResponse`
- `MockTransport`: fakes HTTP for `OpenAIClient`
- `TempDataDir`: isolates filesystem writes

Run: `swift test`

