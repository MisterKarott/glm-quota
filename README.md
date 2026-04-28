# glm-quota

Claude Code plugin for Z.ai/GLM quota monitoring — statusline, detailed quota view, and MCP coherence check.

## Features

- **Statusline** — Colored bar display of token usage (5h/7d windows) and MCP call count with reset timers
- **`/quota` skill** — Detailed quota breakdown on demand via Z.ai API
- **SessionStart hook** — Warns if Zai MCP servers are misconfigured for the active mode

## Requirements

- Claude Code CLI
- A Z.ai/GLM account with API access
- `curl`, `jq` installed

## Installation

```bash
claude plugin add MisterKarott/glm-quota
```

Then configure your statusline in `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/plugins/cache/github-misterk-p2k-glm-quota/glm-quota/scripts/quota-statusline.sh --mode bar",
    "padding": 0
  }
}
```

## Statusline Display

```
⟡ 5h:███░░░░░░░ 31% ↻5j │ 7j:█░░░░░░░░░ 6% ↻4h │ MCP:172/4000 ↻18h
```

- Green: < 70% | Yellow: 70-90% | Red: >= 90%
- Timers show time until reset

## Skills

| Skill | Trigger |
|-------|---------|
| `quota` | `/quota`, "check my quota", "GLM usage" |
| `glm-mode` | Context about GLM mode for other components |

## Hooks

| Event | Action |
|-------|--------|
| `SessionStart` | Checks that Zai MCP servers (`zai-mcp-server`, `web-reader`, `zread`, `duckduckgo`) are enabled/disabled consistently with the active mode |

## Configuration

The plugin reads these environment variables (set by Claude Code from `settings.json`):

- `ANTHROPIC_BASE_URL` — Detects GLM mode (must contain `api.z.ai`)
- `ANTHROPIC_AUTH_TOKEN` — API authentication

## License

MIT
