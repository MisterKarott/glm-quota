<p align="center">
  <strong>glm-quota</strong>
</p>

<p align="center">
  See your context usage and Z.ai quota — right in your Claude Code statusline.
</p>

<p align="center">
  <a href="https://claude.ai/code"><img src="https://img.shields.io/badge/Claude%20Code-Plugin-blue" alt="Claude Code Plugin"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
</p>

---

When you use Claude Code with Z.ai/GLM, you get rate-limited across token windows and MCP calls — but there's no built-in way to see where you stand. glm-quota gives you that visibility in two lines, updated on every turn. It also shows your context window usage so you know when to `/compact` before quality starts dropping.

## Statusline

```
⟡ glm-5.1 [1M] │ Ctx:█████░░░░░ 52% │ 520k/1000k │ ⚡ /compact
  5h:██░░░░░░░░ 22% ↻3h │ 7j:█░░░░░░░░░ 8% ↻6j │ MCP:172/4000 ↻18h
```

**Line 1** — your current model, a visual bar of context usage, the token counter, and a `⚡ /compact` reminder that appears past 50%.

**Line 2** — your Z.ai quota: 5-hour and 7-day token windows, MCP tool call usage, and how long until each window resets.

The plugin activates automatically when you're in GLM mode and stays completely silent otherwise.

## Installation

### Via Marketplace (recommandé)

```bash
claude plugin marketplace add https://github.com/MisterKarott/misterkarott-marketplace
claude plugin install glm-quota
```

### Manuellement

```bash
git clone https://github.com/MisterKarott/glm-quota.git
cd glm-quota
claude plugin install glm-quota
```

Then add this to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ${HOME}/.claude/plugins/cache/github-misterkarott-glm-quota/glm-quota/scripts/quota-statusline.sh --mode bar",
    "padding": 0
  }
}
```

> The cache path may vary. Run `ls ~/.claude/plugins/cache/ | grep glm-quota` after install to confirm.

Restart Claude Code and you're good to go.

## What's checked on startup

Each time you start a session, the plugin verifies that your Z.ai MCP servers are correctly enabled or disabled based on your current mode. If something looks off, you get a warning with a fix suggestion — no silent failures.

## Requirements

- Claude Code CLI
- A Z.ai / GLM account with API access
- `curl` and `jq` (standard on macOS/Linux)

## License

[MIT](LICENSE) — use it, fork it, improve it.
