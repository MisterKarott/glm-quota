<div align="center">

# glm-quota

**Z.ai / GLM Quota Monitor for Claude Code**

Keep an eye on your context usage and Z.ai token limits — directly in your Claude Code statusline.

[![Claude Code Plugin](https://img.shields.io/badge/Claude%20-Plugin-blue)](https://claude.ai/code) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## What it does

Quand tu bosses dans Claude Code en mode Z.ai/GLM, ya deux trucs qui comptent vraiment : savoir ou tu en es du context pour pas que la qualite baisse, et savoir combien de quota il te reste avant de te faire couper en plein milieu d'un truc.

Le probleme, c'est que Claude Code affiche une consommation de context qui ne compte pas les tokens de cache — du coup le chiffre ne colle pas avec ce que tu vois reellement dans le terminal. Et pour le quota Z.ai, tu es aveugle jusqu'a ce que ca bloque.

glm-quota regle ca. Il affiche le vrai pourcentage de context (input + output + cache read + cache creation) et interroge l'API Z.ai pour te montrer tes fenetres de quota. Le tout en deux lignes dans la statusline, mises a jour a chaque tour. Et quand tu arrives a 50% du context, il te rappelle de faire un `/compact` avant que ca devienne urgent.

---

## Statusline display

A compact two-line display that updates on every turn:

```
⟡ glm-5.1 [1M] │ Ctx:█████░░░░░ 17% │ 168k/1000k │ ⚡ /compact
  5h:██░░░░░░░░ 22% ↻3h │ 7j:█░░░░░░░░░ 8% ↻6j │ MCP:172/4000 ↻18h
```

### Line 1 — Context

| Element | What it shows |
|---------|---------------|
| Model name | Currently active model |
| `Ctx:` bar | Visual bar of context window usage |
| Token count | `used/total` in k (e.g. `168k/1000k`) |
| `⚡ /compact` | Appears automatically at 50% context usage |

The context percentage is calculated from **real token consumption** — `input + output + cache_read + cache_creation` — not the simplified number Claude Code reports. So it matches what you actually see in the terminal.

### Line 2 — Z.ai quota

| Element | What it shows |
|---------|---------------|
| `5h:` bar | Token usage in the 5-hour rolling window |
| `7j:` bar | Token usage in the 7-day rolling window |
| `MCP:` counter | MCP tool calls used / daily limit |
| `↻` timer | Time until each window resets |

---

## SessionStart hook — MCP coherence check

When you start a session, the plugin checks that your Z.ai MCP servers (`zai-mcp-server`, `web-reader`, `zread`, `duckduckgo`) are properly enabled or disabled based on your current mode. If something is off, you get a clear warning with a suggested fix.

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

Everything activates on the next session.

---

## How it works

**Context data** comes from the JSON Claude Code pipes to the statusline via stdin. The script extracts token counts and calculates the real percentage including cached tokens.

**Quota data** comes from the Z.ai monitoring API:

```
GET {ANTHROPIC_BASE_URL}/api/monitor/usage/quota/limit
Authorization: {ANTHROPIC_AUTH_TOKEN}
```

It parses `TOKENS_LIMIT` (5h and 7d windows) and `TIME_LIMIT` (MCP calls). Everything runs locally — no data leaves your machine. A 5-minute cache in `/tmp/.glm-quota-cache/` keeps API calls minimal.

---

## Requirements

| Dependency | Why |
|------------|-----|
| Claude Code CLI | Plugin host |
| Z.ai / GLM account with API access | The quota API being queried |
| `curl` | HTTP requests to Z.ai API |
| `jq` | JSON parsing |

---

## Components

| Component | Type | Description |
|-----------|------|-------------|
| `quota-statusline.sh` | Script | Statusline renderer — context bar + Z.ai quota |
| `glm-mode` | Skill | GLM/Zai mode context for other components |
| `check-mcp-coherence.sh` | Hook (SessionStart) | Validates MCP server configuration |

---

## Compatibility

- macOS and Linux (cross-platform `stat` fallback)
- Stays silent when not in GLM mode — outputs nothing for other providers

---

## License

[MIT](LICENSE) — use it, fork it, improve it.

---

<div align="center">

Made with Claude Code

</div>
