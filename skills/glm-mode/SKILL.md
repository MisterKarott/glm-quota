---
name: glm-mode
description: This skill provides context about the GLM/Zai mode in Claude Code. It is used by other plugin components (quota skill, MCP coherence hook) to understand the current mode, required MCP servers, and API configuration. Triggers when the user mentions "GLM mode", "Zai mode", "which MCP for GLM", or when internal plugin components need GLM mode context.
---

## Purpose

Provide authoritative knowledge about GLM/Zai mode configuration in Claude Code, including mode detection, required MCP servers, and API endpoints.

## Mode Detection

GLM mode is active when `settings.json` contains:

```json
"ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic"
```

Detection logic: check if the env var `ANTHROPIC_BASE_URL` matches `*api.z.ai*` or `*bigmodel.cn*`.

## Required MCP Servers (GLM mode only)

When GLM mode is active, these 4 MCP servers must be in `enabledMcpjsonServers`:

1. `zai-mcp-server` — Zai vision/image analysis tools
2. `web-reader` — URL content fetching via Zai
3. `zread` — GitHub repository reading via Zai
4. `duckduckgo` — DuckDuckGo search via Zai

When GLM mode is NOT active (Claude Pro), these 4 must be removed from `enabledMcpjsonServers`.

## API Endpoints

| Purpose | URL |
|---------|-----|
| Base | `${ANTHROPIC_BASE_URL}` (resolves to `https://api.z.ai/api/anthropic`) |
| Quota | `${BASE}/api/monitor/usage/quota/limit` |
| Auth header | `Authorization: ${ANTHROPIC_AUTH_TOKEN}` |

## Settings Files

| File | Role |
|------|------|
| `~/.claude/settings.json` | Active config (currently GLM) |
| `~/.claude/settings.json_glm` | GLM reference |
| `~/.claude/settings.json_claude` | Claude Pro reference |

## Coherence Rules

- `enabledMcpjsonServers` must include the 4 Zai MCPs iff GLM mode is active
- `statusLine.command` should point to the quota script
- Web search: GLM mode → `mcp__duckduckgo__search`, Claude Pro → native `WebSearch`
