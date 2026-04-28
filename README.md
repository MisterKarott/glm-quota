<div align="center">

# glm-quota

**Z.ai / GLM Quota Monitor for Claude Code**

Keep an eye on your Z.ai token usage and MCP call limits — directly in your Claude Code statusline.

[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blue)](https://claude.ai/code) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## What it does

When you're using Claude Code with a **Z.ai / GLM provider**, you get rate-limited across two dimensions:

- **Token windows** — a 5-hour rolling window and a 7-day rolling window
- **MCP tool calls** — a separate daily counter for MCP server invocations

`glm-quota` surfaces all three limits in **real time**, right in your Claude Code statusline. No more guessing when you're about to hit a wall.

### Screenshot

![glm-quota statusline in action](assets/screenshot.png)

---

## Features

### Statusline display

A compact, color-coded bar that updates on every turn:

```
⟡ 5h:██████░░░░ 62% ↻2h │ 7j:███░░░░░░░ 31% ↻5j │ MCP:172/4000 ↻18h
```

- **Color coding**: green (< 70%), yellow (70–90%), red (>= 90%)
- **Reset timers**: shows how long until each window resets (minutes, hours, or days)
- **Smart caching**: queries the Z.ai API only once every 5 minutes to avoid spamming

### `/quota` skill

Type `/quota` or ask "how much quota do I have left?" for a detailed, formatted breakdown of all your limits, percentages, and reset times in a clean box-drawing table.

### MCP coherence check (SessionStart hook)

When you start a session, the plugin automatically checks that your Z.ai MCP servers (`zai-mcp-server`, `web-reader`, `zread`, `duckduckgo`) are properly enabled or disabled based on your current mode (GLM vs Claude Pro). If something is misconfigured, you get a clear warning with a suggested fix.

---

## Installation

### 1. Install the plugin

```bash
claude plugin add MisterKarott/glm-quota
```

### 2. Configure the statusline

Add this to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ${HOME}/.claude/plugins/cache/github-misterkarott-glm-quota/glm-quota/scripts/quota-statusline.sh --mode bar",
    "padding": 0
  }
}
```

> The exact cache path may vary. Check with `ls ~/.claude/plugins/cache/ | grep glm-quota` after installation.

### 3. Restart Claude Code

The statusline, hook, and skills will activate on the next session.

---

## How it works

The plugin queries the Z.ai monitoring API:

```
GET {ANTHROPIC_BASE_URL}/api/monitor/usage/quota/limit
Authorization: {ANTHROPIC_AUTH_TOKEN}
```

It parses the response to extract:
- `TOKENS_LIMIT` entries (5h and 7d windows) with percentage and next reset time
- `TIME_LIMIT` entry (MCP calls) with current/max usage

Everything runs locally — no data leaves your machine. The script uses a 5-minute cache file in `/tmp/.glm-quota-cache/` to minimize API calls.

---

## Requirements

| Dependency | Why |
|------------|-----|
| Claude Code CLI | Plugin host |
| Z.ai / GLM account with API access | The quota API being queried |
| `curl` | HTTP requests to Z.ai API |
| `jq` | JSON parsing |

---

## Configuration

The plugin reads environment variables set by Claude Code from your `settings.json`:

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_BASE_URL` | Detects GLM mode (must contain `api.z.ai`) |
| `ANTHROPIC_AUTH_TOKEN` | Authenticates with the Z.ai quota API |

No additional configuration files needed — it just works when you're in GLM mode, and stays silent when you're not.

---

## Components

| Component | Type | Description |
|-----------|------|-------------|
| `quota-statusline.sh` | Script | Statusline renderer with caching and color output |
| `quota` | Skill | Detailed quota view on demand |
| `glm-mode` | Skill | GLM/Zai mode context for other components |
| `check-mcp-coherence.sh` | Hook (SessionStart) | Validates MCP server configuration |

---

## Compatibility

- **macOS** and **Linux** supported (cross-platform `stat` fallback)
- Automatically disables itself when not in GLM mode (outputs nothing for non-Z.ai providers)

---

## License

[MIT](LICENSE) — use it, fork it, improve it.

---

<div align="center">

Made with Claude Code

</div>
