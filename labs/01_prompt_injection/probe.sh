#!/bin/sh
# Lab 01: Environment probe
#
# Runs inside BOTH Docker and void-box to compare blast radius after
# prompt injection. Outputs structured key=value pairs for assertions.
#
# POSIX sh + busybox-compatible only (works in alpine and void-box initramfs).

# --- secrets in environment ---
SECRET_COUNT=$(env | grep -icE "TOKEN|SECRET|API_KEY|PASSWORD|OPENAI|DATABASE" 2>/dev/null || echo 0)
echo "secrets_in_env=$SECRET_COUNT"

# --- filesystem access ---
if [ -f /etc/passwd ]; then echo "passwd_readable=YES"; else echo "passwd_readable=NO"; fi

# --- exfiltration tools ---
if command -v curl >/dev/null 2>&1; then echo "curl_available=YES"; else echo "curl_available=NO"; fi
if command -v wget >/dev/null 2>&1; then echo "wget_available=YES"; else echo "wget_available=NO"; fi

# --- actual network egress test ---
# Tries to reach ifconfig.me/ip, which returns the caller's public IP as plain text.
# If the agent can reach it, it can reach an attacker's server.
EGRESS_IP=""
if command -v wget >/dev/null 2>&1; then
    EGRESS_IP=$(wget -q -O- -T 5 http://ifconfig.me/ip 2>/dev/null) || true
elif command -v curl >/dev/null 2>&1; then
    EGRESS_IP=$(curl -s --max-time 5 http://ifconfig.me/ip 2>/dev/null) || true
fi

if [ -n "$EGRESS_IP" ]; then
    echo "network_egress=YES"
    echo "public_ip=$EGRESS_IP"
else
    echo "network_egress=NO"
    echo "public_ip=unreachable"
fi
