#!/usr/bin/env bash
# Shared output helpers for all labs.
# Source this file: source "$(dirname "$0")/../lib/output.sh"
#
# Provides:
#   Terminal colors (auto-disabled when piped):
#     C_RED, C_GREEN, C_YELLOW, C_CYAN, C_BOLD, C_DIM, C_RESET
#
#   Semantic output functions:
#     header <text>         — bold section header with ━━━ bars
#     title <text>          — bold inline text (no bars)
#     dim <text>            — dimmed/muted text
#     danger <text>         — red text for dangerous values/results
#     safe <text>           — green text for safe values/results
#     label <text>          — cyan label for probe sections
#     pass <text>           — green [PASS] assertion
#     fail <text>           — red [FAIL] assertion
#     warn <text>           — yellow [WARN] assertion
#     result_bad <text>     — bold red result line
#     result_good <text>    — bold green result line
#
#   Utility:
#     parse_val <text> <key> — extract value from key=value output

# ─────────────────────────────────────────────
# Terminal colors (auto-disabled when piped)
# ─────────────────────────────────────────────
if [ -t 1 ]; then
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_CYAN='\033[0;36m'
    C_BOLD='\033[1m'
    C_DIM='\033[2m'
    C_RESET='\033[0m'
else
    C_RED='' C_GREEN='' C_YELLOW='' C_CYAN='' C_BOLD='' C_DIM='' C_RESET=''
fi

# ─────────────────────────────────────────────
# Semantic output functions
# ─────────────────────────────────────────────

header() {
    echo ""
    echo -e "${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$*"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo ""
}

title()       { echo -e "${C_BOLD}$*${C_RESET}"; }
dim()         { echo -e "${C_DIM}$*${C_RESET}"; }
danger()      { echo -e "${C_RED}$*${C_RESET}"; }
safe()        { echo -e "${C_GREEN}$*${C_RESET}"; }
label()       { echo -e "${C_CYAN}$*${C_RESET}"; }

pass()        { echo -e "    ${C_GREEN}[PASS]${C_RESET} $*"; }
fail()        { echo -e "    ${C_RED}[FAIL]${C_RESET} $*"; }
warn()        { echo -e "    ${C_YELLOW}[WARN]${C_RESET} $*"; }

result_bad()  { echo -e "${C_RED}${C_BOLD}$*${C_RESET}"; }
result_good() { echo -e "${C_GREEN}${C_BOLD}$*${C_RESET}"; }

# ─────────────────────────────────────────────
# Utility
# ─────────────────────────────────────────────

# Extract a value from structured key=value output.
# Usage: val=$(parse_val "$output" "key_name")
parse_val() { echo "$1" | sed -n "s/^${2}=//p" | tr -d '[:space:]'; }
