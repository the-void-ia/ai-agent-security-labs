#!/bin/sh
# Lab 02: Docker Socket Escape probe
#
# Runs inside BOTH Docker (with socket mounted) and void-box to compare
# escape capability. Outputs structured key=value pairs for assertions.
#
# In Docker (docker:latest image): docker CLI is available, socket is mounted,
# so sibling container checks succeed.
# In void-box: no docker CLI, no socket — all checks fail gracefully.

# --- Docker socket accessible? ---
if [ -S /var/run/docker.sock ]; then
    echo "docker_socket=YES"
else
    echo "docker_socket=NO"
fi

# --- Docker CLI available? ---
if command -v docker >/dev/null 2>&1; then
    echo "docker_cli=YES"
else
    echo "docker_cli=NO"
fi

# --- Can query host Docker daemon? ---
DAEMON_ID=$(docker info --format '{{.ID}}' 2>/dev/null || echo "")
if [ -n "$DAEMON_ID" ]; then
    echo "can_query_daemon=YES"
    echo "daemon_id=$DAEMON_ID"
else
    echo "can_query_daemon=NO"
    echo "daemon_id=none"
fi

# --- Can read host files via sibling container? ---
HOST_HOSTNAME=$(docker run --rm -v /etc/hostname:/host/hostname:ro alpine:latest \
    cat /host/hostname 2>/dev/null | tr -d '[:space:]' || echo "")
if [ -n "$HOST_HOSTNAME" ]; then
    echo "can_read_host=YES"
    echo "host_hostname=$HOST_HOSTNAME"
else
    echo "can_read_host=NO"
    echo "host_hostname=none"
fi

# --- Can write to host filesystem via sibling container? ---
WRITE_OK="NO"
docker run --rm -v /tmp:/host/tmp alpine:latest \
    sh -c 'echo PROOF > /host/tmp/lab02_probe_proof.txt' 2>/dev/null || true
PROOF=$(docker run --rm -v /tmp:/host/tmp:ro alpine:latest \
    cat /host/tmp/lab02_probe_proof.txt 2>/dev/null | tr -d '[:space:]' || echo "")
docker run --rm -v /tmp:/host/tmp alpine:latest \
    rm -f /host/tmp/lab02_probe_proof.txt 2>/dev/null || true
if [ "$PROOF" = "PROOF" ]; then
    WRITE_OK="YES"
fi
echo "can_write_host=$WRITE_OK"

# --- Environment info ---
echo "probe_hostname=$(hostname)"
echo "probe_kernel=$(uname -r)"
