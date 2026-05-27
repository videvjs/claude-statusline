#!/usr/bin/env bash
# Claude Code status line: folder, git branch, model, context percentage with progress bar
input=$(cat)

# Parse JSON with python3 (jq isn't installed). Fields are tab-separated.
parsed=$(printf '%s' "$input" | python3 -c '
import json, sys
d = json.load(sys.stdin)
cwd = (d.get("workspace") or {}).get("current_dir") or d.get("cwd") or ""
m = d.get("model") or {}
model = m.get("display_name") or m.get("id") or "Claude"
cw = d.get("context_window") or {}
pct = cw.get("used_percentage")
effort_obj = d.get("effort") or {}
effort = effort_obj.get("level") or ""
rl = d.get("rate_limits") or {}
five_h = (rl.get("five_hour") or {}).get("used_percentage")
five_h_reset = (rl.get("five_hour") or {}).get("resets_at")
seven_d = (rl.get("seven_day") or {}).get("used_percentage")
sys.stdout.write("\t".join([cwd, model, "" if pct is None else str(pct), effort, "" if five_h is None else str(five_h), "" if five_h_reset is None else str(int(five_h_reset)), "" if seven_d is None else str(seven_d)]))
')

IFS=$'\t' read -r cwd model used_pct effort five_h_pct five_h_reset seven_d_pct <<< "$parsed"

folder=$(basename "$cwd")

branch=$(git --git-dir="$cwd/.git" --work-tree="$cwd" symbolic-ref --short HEAD 2>/dev/null \
         || git --git-dir="$cwd/.git" --work-tree="$cwd" rev-parse --short HEAD 2>/dev/null)

build_bar() {
  local pct=$1
  local width=10
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty; i++ )); do  bar="${bar}░"; done
  printf "%s" "$bar"
}

parts=()
[ -n "$folder" ] && parts+=("/$folder")
[ -n "$branch" ] && parts+=("($branch)")
if [ -n "$model" ]; then
  m_color='\033[38;2;210;170;90m'
  m_reset='\033[0m'
  if [ -n "$effort" ]; then
    parts+=("${m_color}${model}${m_reset} [$effort]")
  else
    parts+=("${m_color}${model}${m_reset}")
  fi
fi
if [ -n "$used_pct" ]; then
  pct_int=$(printf "%.0f" "$used_pct")
  bar=$(build_bar "$pct_int")
  if [ "$pct_int" -gt 70 ]; then
    ctx_color='\033[31m'
    ctx_reset='\033[0m'
  elif [ "$pct_int" -gt 40 ]; then
    ctx_color='\033[33m'
    ctx_reset='\033[0m'
  else
    ctx_color='\033[38;2;129;140;248m'
    ctx_reset='\033[0m'
  fi
  parts+=("${ctx_color}ctx [${bar}] ${pct_int}%${ctx_reset}")
fi
if [ -n "$five_h_pct" ]; then
  five_int=$(printf "%.0f" "$five_h_pct")
  bar=$(build_bar "$five_int")
  if   [ "$five_int" -le 40 ]; then color='\033[38;2;76;175;80m'
  elif [ "$five_int" -le 70 ]; then color='\033[33m'
  else                               color='\033[31m'
  fi
  reset='\033[0m'
  countdown=""
  if [ -n "$five_h_reset" ]; then
    now=$(date +%s)
    diff=$(( five_h_reset - now ))
    if [ "$diff" -gt 0 ]; then
      h=$(( diff / 3600 ))
      m=$(( (diff % 3600) / 60 ))
      if [ "$h" -gt 0 ]; then
        countdown=" Reset in ${h}h${m}m"
      else
        countdown=" Reset in ${m}m"
      fi
    fi
  fi
  parts+=("· 5h ${color}[${bar}] ${five_int}%${reset}${countdown}")
fi
if [ -n "$seven_d_pct" ]; then
  seven_int=$(printf "%.0f" "$seven_d_pct")
  if [ "$seven_int" -ge 30 ]; then
    bar=$(build_bar "$seven_int")
    if   [ "$seven_int" -le 40 ]; then color='\033[38;2;76;175;80m'
    elif [ "$seven_int" -le 70 ]; then color='\033[33m'
    else                                color='\033[31m'
    fi
    reset='\033[0m'
    parts+=("7d ${color}[${bar}] ${seven_int}%${reset}")
  fi
fi

(IFS=" | "; printf '%b' "${parts[*]}")
