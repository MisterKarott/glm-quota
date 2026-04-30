<p align="center">
  <strong>glm-quota</strong>
</p>

<p align="center">
  Z.ai / GLM quota monitor for Claude Code — context window + token limits, right in your statusline.
</p>

<p align="center">
  <a href="https://claude.ai/code"><img src="https://img.shields.io/badge/Claude%20Code-Plugin-blue" alt="Claude Code Plugin"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
</p>

---

When you're deep in a Claude Code session using Z.ai/GLM, two things matter: how much context you've burned through, and how much quota you've got left before you hit a wall.

The problem is that Claude Code's built-in context display doesn't count cached tokens — so the number it shows doesn't match what you actually see in the terminal. And for Z.ai quota, you're flying blind until something breaks.

glm-quota fixes both. It shows the real context percentage (counting input, output, cache reads, and cache creations) and queries the Z.ai API for your token windows and MCP limits. All in two lines in your statusline, updated on every turn. And when you cross 50% context, it drops a `⚡ /compact` reminder so you can compact before quality drops.

## Statusline

```
⟡ glm-5.1 [1M] │ Ctx:█████░░░░░ 52% │ 520k/1000k │ ⚡ /compact
  5h:██░░░░░░░░ 22% ↻3h │ 7j:█░░░░░░░░░ 8% ↻6j │ MCP:172/4000 ↻18h
```

**Line 1** — model, context bar (real tokens with cache), token counter, and a `/compact` nudge past 50%.

**Line 2** — Z.ai quota: 5-hour token window, 7-day token window, MCP call counter, and reset timers.

The context percentage is calculated from **real token consumption** (`input + output + cache_read + cache_creation`) — not the simplified number Claude Code reports. So it matches what you actually see in the terminal.

## Installation

```bash
# 1. Install the plugin
claude plugin add MisterKarott/glm-quota

# 2. Add to ~/.claude/settings.json
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ${HOME}/.claude/plugins/cache/github-misterkarott-glm-quota/glm-quota/scripts/quota-statusline.sh --mode bar",
    "padding": 0
  }
}
```

> The cache path may vary. Check with `ls ~/.claude/plugins/cache/ | grep glm-quota` after install.

Restart Claude Code and everything activates on the next session.

## How it works

Context data comes from the JSON Claude Code pipes to the statusline via stdin. The script extracts token counts and calculates the real percentage including cached tokens.

Quota data comes from the Z.ai monitoring API:

```
GET {ANTHROPIC_BASE_URL}/api/monitor/usage/quota/limit
Authorization: {ANTHROPIC_AUTH_TOKEN}
```

It parses `TOKENS_LIMIT` (5h and 7d windows) and `TIME_LIMIT` (MCP calls). Everything runs locally — no data leaves your machine. A 5-minute cache in `/tmp/.glm-quota-cache/` keeps API calls minimal.

The plugin stays silent when not in GLM mode — outputs nothing for other providers.

## SessionStart hook

On session start, the plugin checks that your Z.ai MCP servers (`zai-mcp-server`, `web-reader`, `zread`, `duckduckgo`) are properly enabled or disabled based on your current mode. If something is off, you get a clear warning with a suggested fix.

## Requirements

| Dependency | Why |
|------------|-----|
| Claude Code CLI | Plugin host |
| Z.ai / GLM API access | Quota endpoint |
| `curl` | HTTP requests |
| `jq` | JSON parsing |

macOS and Linux supported (cross-platform `stat` fallback).

## License

[MIT](LICENSE) — use it, fork it, improve it.
