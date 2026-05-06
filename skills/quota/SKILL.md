---
name: quota
description: This skill is triggered when the user runs "/quota" or asks to "check my quota", "show quota", "how much quota left", "GLM usage", "Z.ai usage". Displays a detailed, formatted view of the current Z.ai/GLM quota by querying the API directly.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

## Purpose

Query the Z.ai/GLM quota API and display a detailed, human-readable breakdown of token limits and MCP usage with reset timers.

## When to use

Trigger on `/quota` slash command or when the user explicitly asks about their current GLM/Z.ai quota, usage, or limits.

## Procedure

### 1. Check mode

Verify the session is in GLM mode by checking `ANTHROPIC_BASE_URL` contains `api.z.ai` or `bigmodel.cn`. If not, inform the user this command only works in GLM/Zai mode and stop.

### 2. Query the API

Execute the quota fetch script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/quota-statusline.sh --mode text"
```

If a more detailed view is needed, query the API directly:

```bash
curl -s --max-time 8 \
  -H "Authorization: ${ANTHROPIC_AUTH_TOKEN}" \
  -H "Accept-Language: en-US" \
  -H "Content-Type: application/json" \
  "${ANTHROPIC_BASE_URL%%/api/anthropic*}/api/monitor/usage/quota/limit"
```

### 3. Format the output

Parse the JSON response and display:

- **Token windows**: For each `TOKENS_LIMIT` entry, show:
  - Window label (5h window, 7-day window)
  - Current percentage with color indicator (green < 70%, yellow 70-90%, red ≥ 90%)
  - Next reset time formatted as relative duration (e.g., "2h 15m", "3j")

- **MCP usage**: For `TIME_LIMIT` entry, show:
  - Current value / max value
  - Next reset time

- **Summary line**: Highest token usage percentage with emoji indicator

### 4. Output format

```
╔══════════════════════════════════════╗
║        GLM Quota — Detailed         ║
╠══════════════════════════════════════╣
║ Tokens (5h)    ██████░░░░  62%      ║
║   Reset: 2h 15m                      ║
║ Tokens (7j)    ███░░░░░░░  28%      ║
║   Reset: 5j                          ║
║ MCP calls      127/500               ║
║   Reset: 18h                         ║
╠══════════════════════════════════════╣
║ Status: OK (highest: 62%)            ║
╚══════════════════════════════════════╝
```

### Edge cases

- API unreachable → show error with the endpoint tried
- No GLM mode → explain the command requires Z.ai/GLM mode
- Empty response → show "quota data unavailable"
