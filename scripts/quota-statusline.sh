#!/bin/bash
# Statusline script for GLM mode — fetches and displays Z.ai quota
# Uses a 5-minute cache to avoid API spam
# Reads JSON from stdin (Claude Code statusLine) or runs standalone

MODE="bar"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# If stdin has data (piped by Claude Code), try the old rate_limits format
if [[ ! -t 0 ]]; then
  input=$(cat 2>/dev/null || true)
  if [[ -n "$input" ]]; then
    five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
    seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
    cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
    ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
    ctx_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens + .context_window.total_output_tokens // empty' 2>/dev/null)
    ctx_total=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
    model_name=$(echo "$input" | jq -r '.model.display_name // .model.id // empty' 2>/dev/null)
    if [[ -n "$five_h" || -n "$seven_d" ]]; then
      # Delegate to old rendering logic
      output="⟡ "
      if [[ -n "$five_h" ]]; then output+="5h: ${five_h}%"; fi
      if [[ -n "$five_h" && -n "$seven_d" ]]; then output+=" │ "; fi
      if [[ -n "$seven_d" ]]; then output+="7d: ${seven_d}%"; fi
      if [[ -n "$cost_usd" ]]; then
        cost_fmt=$(printf '%.4f' "$cost_usd" 2>/dev/null)
        [[ -n "$five_h" || -n "$seven_d" ]] && output+=" │ "
        output+="\$${cost_fmt}"
      fi
      echo "$output"
      exit 0
    fi
  fi
fi

# --- GLM standalone mode: query Z.ai API directly ---

BASE_URL="${ANTHROPIC_BASE_URL:-}"
AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"

# Only run in GLM mode
if [[ -z "$AUTH_TOKEN" || ! "$BASE_URL" =~ api\.z\.ai|bigmodel\.cn ]]; then
  echo ""
  exit 0
fi

# Parse base domain
proto="${BASE_URL%%://*}"
host="${BASE_URL#*://}"
host="${host%%/*}"
BASE="https://${host}"

# Cache: 5 min TTL
CACHE_DIR="/tmp/.glm-quota-cache"
CACHE_FILE="${CACHE_DIR}/quota.json"
mkdir -p "$CACHE_DIR" 2>/dev/null

now_s=$(date +%s)
cache_age=999999
if [[ -f "$CACHE_FILE" ]]; then
  cache_ts=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  cache_age=$(( now_s - cache_ts ))
fi

if (( cache_age < 300 )) && [[ -f "$CACHE_FILE" ]]; then
  data=$(cat "$CACHE_FILE")
else
  data=$(curl -s --max-time 8 \
    -H "Authorization: ${AUTH_TOKEN}" \
    -H "Accept-Language: en-US" \
    -H "Content-Type: application/json" \
    "${BASE}/api/monitor/usage/quota/limit" 2>/dev/null)
  if [[ $? -eq 0 && -n "$data" ]]; then
    echo "$data" > "$CACHE_FILE"
  fi
fi

if [[ -z "$data" ]]; then
  echo "⟡ quota: --"
  exit 0
fi

# Parse limits from JSON
token_5h=""
token_5h_2=""
mcp_pct=""
mcp_cur=""
mcp_max=""
reset_5h=""
reset_7d=""
reset_mcp=""

idx=0
limit_count=$(echo "$data" | jq '.data.limits | length' 2>/dev/null)

for (( i=0; i<limit_count; i++ )); do
  ltype=$(echo "$data" | jq -r ".data.limits[$i].type" 2>/dev/null)
  lpct=$(echo "$data" | jq -r ".data.limits[$i].percentage // 0" 2>/dev/null)
  lreset=$(echo "$data" | jq -r ".data.limits[$i].nextResetTime // empty" 2>/dev/null)

  if [[ "$ltype" == "TOKENS_LIMIT" ]]; then
    if [[ -z "$token_5h" ]]; then
      token_5h="$lpct"
      reset_5h="$lreset"
    else
      token_5h_2="$lpct"
      reset_7d="$lreset"
    fi
  elif [[ "$ltype" == "TIME_LIMIT" ]]; then
    mcp_pct="$lpct"
    mcp_cur=$(echo "$data" | jq -r ".data.limits[$i].currentValue // 0" 2>/dev/null)
    mcp_max=$(echo "$data" | jq -r ".data.limits[$i].usage // 0" 2>/dev/null)
    reset_mcp="$lreset"
  fi
done

# Format nextResetTime (ms epoch) → Xm / HH:MM / Xj
fmt_reset() {
  local ms="${1%%.*}"
  [[ -z "$ms" || "$ms" == "null" ]] && return
  local s=$(( ms / 1000 ))
  local now=$(date +%s)
  local diff=$(( s - now ))
  if (( diff <= 0 )); then
    printf 'now'
  elif (( diff < 3600 )); then
    printf '%dm' $(( (diff + 59) / 60 ))
  elif (( diff < 86400 )); then
    printf '%dh' $(( (diff + 1800) / 3600 ))
  else
    printf '%dj' $(( (diff + 43200) / 86400 ))
  fi
}

# Use the higher of the two token windows for "worst case" display
token_worst="$token_5h"
if [[ -n "$token_5h_2" ]]; then
  if (( ${token_5h_2%.*} > ${token_5h%.*} )); then
    token_worst="$token_5h_2"
  fi
fi

# Render bar segment (1st arg: percentage, 2nd arg: "1d" for 1 decimal)
render_bar() {
  local pct="${1%.*}"
  pct=${pct:-0}
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100

  local color reset=''
  if (( pct >= 90 )); then color=''
  elif (( pct >= 70 )); then color=''
  else color=''
  fi

  local fmt_pct="$pct"
  if [[ "$2" == "1d" ]]; then
    fmt_pct=$(printf '%.1f' "$1" 2>/dev/null)
  fi

  if [[ "$MODE" == "text" ]]; then
    printf "${color}%s%%${reset}" "$fmt_pct"
    return
  fi

  local filled=$(( (pct + 5) / 10 ))
  local empty=$(( 10 - filled ))
  (( filled > 10 )) && filled=10
  local bar=""
  for (( j=0; j<filled; j++ )); do bar+="█"; done
  for (( j=0; j<empty; j++ )); do bar+="░"; done
  printf "${color}%s %s%%${reset}" "$bar" "$fmt_pct"
}

# Build output — 2 lines
line1="⟡ Model:"
line2="  "
if [[ -n "$model_name" ]]; then
  line1+=" ${model_name}"
fi
if [[ -n "$ctx_pct" ]]; then
  line1+=" │ Ctx:$(render_bar "$ctx_pct" "1d")"
  if [[ -n "$ctx_tokens" && -n "$ctx_total" ]]; then
    ctx_fmt=$(( ctx_tokens / 1000 ))
    line1+=" │ Tk: ${ctx_fmt}k"
  fi
fi
if [[ -n "$token_5h" ]]; then
  line2+="5h:$(render_bar "$token_5h")"
  if [[ -n "$reset_5h" ]]; then line2+=" ↻$(fmt_reset "$reset_5h")"; fi
fi
if [[ -n "$token_5h_2" ]]; then
  line2+=" │ 7j:$(render_bar "$token_5h_2")"
  if [[ -n "$reset_7d" ]]; then line2+=" ↻$(fmt_reset "$reset_7d")"; fi
fi
if [[ -n "$mcp_pct" ]]; then
  [[ -n "$token_5h" || -n "$token_5h_2" ]] && line2+=" │ "
  line2+="MCP:${mcp_cur}/${mcp_max}"
  if [[ -n "$reset_mcp" ]]; then line2+=" ↻$(fmt_reset "$reset_mcp")"; fi
fi
printf '%b\n%b\n' "$line1" "$line2"
