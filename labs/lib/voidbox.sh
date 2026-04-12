#!/usr/bin/env bash
# Void-box helpers for all labs.
# Source this file: source "$(dirname "$0")/../lib/voidbox.sh"
#
# Provides:
#   VOIDBOX_AVAILABLE  — true/false
#   voidbox_status             — print availability info
#   run_in_voidbox <name> <cmd> — run command in a micro-VM
#   voidbox_ok <result>        — check if run succeeded
#   voidbox_output <result>    — extract command output
#
# Requires: source output.sh first (for colors used in voidbox_status).

# ─────────────────────────────────────────────
# Locate voidbox binary
# ─────────────────────────────────────────────
# Override with VOIDBOX_BIN to use a local build.
# When using a local build, also set VOID_BOX_KERNEL and VOID_BOX_INITRAMFS.
VOIDBOX_BIN="${VOIDBOX_BIN:-}"
if [ -z "$VOIDBOX_BIN" ]; then
    if command -v voidbox &>/dev/null; then
        VOIDBOX_BIN="voidbox"
    fi
fi

VOIDBOX_AVAILABLE=false
if [ -n "$VOIDBOX_BIN" ] && { [ -x "$VOIDBOX_BIN" ] || command -v "$VOIDBOX_BIN" &>/dev/null 2>&1; }; then
    VOIDBOX_AVAILABLE=true
fi

# Print void-box availability status. Call once at the start of a lab.
voidbox_status() {
    if $VOIDBOX_AVAILABLE; then
        echo "[*] void-box detected: $VOIDBOX_BIN"
    else
        echo "[*] void-box not found — void-box sections will show expected behavior."
        echo "    Install: curl -fsSL https://raw.githubusercontent.com/the-void-ia/void-box/main/scripts/install.sh | sh"
        echo "    Or set VOIDBOX_BIN, VOID_BOX_KERNEL, and VOID_BOX_INITRAMFS for a local build."
    fi
}

# ─────────────────────────────────────────────
# Run a shell command inside a void-box micro-VM
# ─────────────────────────────────────────────
# Creates a temporary workflow spec (kind: workflow) and runs it.
# No LLM provider or API keys required.
#
# Usage: RESULT=$(run_in_voidbox <name> <shell_command>)
# Output: first line is "OK" or "FAIL", rest is command output or error.
run_in_voidbox() {
    local name="$1"
    local cmd="$2"
    local tmpdir
    local spec_file
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/voidbox-lab.XXXXXX" 2>/dev/null || mktemp -d -t voidbox-lab)
    spec_file="$tmpdir/spec.yaml"

    # Write the YAML spec with the shell command as a block scalar.
    # Every line of $cmd must be indented to the YAML block level (12 spaces).
    local indented_cmd
    indented_cmd=$(echo "$cmd" | sed 's/^/            /')

    cat > "$spec_file" <<EOF
api_version: v1
kind: workflow
name: ${name}

sandbox:
  mode: auto
  memory_mb: 1024
  vcpus: 1

workflow:
  steps:
    - name: ${name}
      run:
        program: sh
        args:
          - -c
          - |
${indented_cmd}
  output_step: ${name}
EOF

    local raw_output
    raw_output=$("$VOIDBOX_BIN" run --file "$spec_file" --no-banner 2>&1)
    rm -rf "$tmpdir"

    if echo "$raw_output" | grep -q "success: true"; then
        echo "OK"
        echo "$raw_output" | sed -n '/^output:/,$ { /^output:/d; p; }'
    else
        echo "FAIL"
        local error_msg
        error_msg=$(echo "$raw_output" | sed 's/\x1b\[[0-9;]*m//g' | grep -i "FAILED\|error\|failed" | head -1)
        echo "${error_msg:-void-box run failed (unknown error)}"
    fi
}

# Check if a run_in_voidbox result was successful.
voidbox_ok() { [ "$(echo "$1" | head -1)" = "OK" ]; }

# Extract the command output from a run_in_voidbox result (strips status line).
voidbox_output() { echo "$1" | tail -n +2; }
