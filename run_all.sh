#!/usr/bin/env bash
set -euo pipefail

# Run all AI Agent Security Labs in sequence.
# Each lab runs its Docker exploit and (if void-box is available) the void-box comparison.

echo "=== AI Agent Security Labs ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

for lab in "$SCRIPT_DIR"/labs/0*_*/exploit.sh; do
    lab_dir=$(dirname "$lab")
    lab_name=$(basename "$lab_dir")

    echo "╔══════════════════════════════════════════════╗"
    echo "║  $lab_name"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    if bash "$lab"; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        echo "[!] Lab $lab_name exited with errors."
    fi

    echo ""
    echo ""
done

echo "=== Done: $PASS passed, $FAIL failed ==="
