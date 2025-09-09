# CLI

Executable: `connectonion-cli`

## Commands (planned)

- `chat`: Run an agent loop with optional tools
  - `--task <string>`: User request
  - `--model <id>`: LLM model (default `gpt-4o-mini`)
  - `--api-key <key>`: Overrides `OPENAI_API_KEY`
  - `--base-url <url>`: Overrides `OPENAI_BASE_URL`
  - `--data-dir <path>`: History path, default `./.connectonion`
  - `--max-steps <n>`: Cap iterations
  - `--trace`: Enable step tracing output
  - `--tool <name>`: Restrict to a specific tool if provided

## Examples

```
swift run connectonion-cli chat --task "Say hi" \
  --api-key $OPENAI_API_KEY --trace
```

```
swift run connectonion-cli chat --task "Take a screenshot" \
  --tool screenshot --data-dir ./.connectonion
```

