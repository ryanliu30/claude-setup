#!/usr/bin/env bash
# Statusline for Claude Code — parses JSON from stdin, displays model/context/git info.
# Requires: jq

input=$(cat)

model=$(echo "$input" | jq -r '.model // "unknown"' 2>/dev/null | sed 's/claude-//' | sed 's/-2[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$//')
dir=$(basename "$PWD")

# Token usage
input_tokens=$(echo "$input" | jq -r '.usage.input_tokens // 0' 2>/dev/null)
output_tokens=$(echo "$input" | jq -r '.usage.output_tokens // 0' 2>/dev/null)
context_used=$(echo "$input" | jq -r '.context_window.used // 0' 2>/dev/null)
context_max=$(echo "$input" | jq -r '.context_window.max // 200000' 2>/dev/null)

# Git branch
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Context percentage
if [ "$context_max" -gt 0 ] 2>/dev/null; then
  pct=$(( context_used * 100 / context_max ))
else
  pct=0
fi

# Color based on usage
if   [ "$pct" -ge 90 ]; then color="\033[38;2;220;50;50m"
elif [ "$pct" -ge 75 ]; then color="\033[38;2;230;130;0m"
elif [ "$pct" -ge 50 ]; then color="\033[38;2;230;200;0m"
else                          color="\033[38;2;80;200;120m"
fi
reset="\033[0m"

# Format token counts
fmt_tokens() {
  local n=$1
  if   [ "$n" -ge 1000000 ]; then printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
  elif [ "$n" -ge 1000 ];    then printf "%.0fK" "$(echo "scale=0; $n/1000" | bc)"
  else                            echo "$n"
  fi
}

in_fmt=$(fmt_tokens "$input_tokens")
out_fmt=$(fmt_tokens "$output_tokens")

# Progress bar (20 chars wide)
bar_width=20
filled=$(( pct * bar_width / 100 ))
empty=$(( bar_width - filled ))
bar="$(printf '%0.s█' $(seq 1 $filled 2>/dev/null))$(printf '%0.s░' $(seq 1 $empty 2>/dev/null))"

# Rate limits
reset_5h=$(echo "$input" | jq -r '.rate_limits.requests_5h.reset_at // ""' 2>/dev/null)
remaining_5h=$(echo "$input" | jq -r '.rate_limits.requests_5h.remaining // ""' 2>/dev/null)

# Line 1: model | dir (branch) | tokens
line1="  ${model}"
[ -n "$branch" ] && line1+="  ${dir} (${branch})" || line1+="  ${dir}"
line1+="  ↑${in_fmt} ↓${out_fmt}"
[ -n "$remaining_5h" ] && line1+="  limit:${remaining_5h}"

# Line 2: context bar
line2=$(printf "  ${color}[%s]${reset} %d%% (%d/%d)" "$bar" "$pct" "$context_used" "$context_max")

printf "%s\n%b\n" "$line1" "$line2"
