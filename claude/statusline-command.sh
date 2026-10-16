#!/usr/bin/env bash
# Claude Code status line command
# Reads JSON from stdin and outputs: model, context window usage, rate limits

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown model"')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  ctx=$(printf "ctx: %.0f%% used" "$used_pct")
else
  ctx="ctx: --"
fi

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate_parts=()
if [ -n "$five_pct" ]; then
  rate_parts+=("5h: $(printf '%.0f' "$five_pct")%")
fi
if [ -n "$week_pct" ]; then
  rate_parts+=("7d: $(printf '%.0f' "$week_pct")%")
fi

if [ ${#rate_parts[@]} -gt 0 ]; then
  rate_str=$(IFS=" | "; echo "${rate_parts[*]}")
  printf "%s | %s | %s" "$model" "$ctx" "$rate_str"
else
  printf "%s | %s" "$model" "$ctx"
fi
