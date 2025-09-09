# History JSON Schema

The Swift port mirrors Python ConnectOnion’s history format to enable cross-replay and shared tooling.

## File Location

- Default: `./.connectonion/agents/{name}/behavior.json`

## Record Structure

Top-level is an array of behavior records:

```
[
  {
    "timestamp": "2025-01-01T12:00:00Z",
    "agent": "demo",
    "task": "...",
    "messages": [ {"role":"user","content":"..."}, {"role":"assistant","content":"..."} ],
    "tool_calls": [
      {
        "name": "fill_input",
        "args": {"selector": "#q", "text": "..."},
        "result": {"ok": true},
        "timing_ms": 123
      }
    ],
    "metadata": {"model":"gpt-4o-mini"}
  }
]
```

Exact field names will map directly from Python where applicable. Minor differences may be present where Swift naming differs; semantic parity is the goal.

