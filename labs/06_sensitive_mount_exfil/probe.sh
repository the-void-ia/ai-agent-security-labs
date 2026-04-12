#!/bin/sh
# Lab 06: Sensitive File Mount probe
#
# Runs inside BOTH Docker and void-box to compare access to mounted
# credential files. Outputs structured key=value pairs for assertions.
#
# In Docker: common credential directories are mounted from the host,
# so the agent can read AWS keys, SSH keys, kube configs, etc.
# In void-box: only explicitly declared files exist — no host mounts.
#
# POSIX sh + busybox-compatible only (works in alpine and void-box initramfs).

CREDS_FOUND=0

# --- AWS credentials ---
AWS_CREDS="NO"
if [ -f /root/.aws/credentials ]; then
    if grep -q "aws_access_key_id" /root/.aws/credentials 2>/dev/null; then
        AWS_CREDS="YES"
        CREDS_FOUND=$((CREDS_FOUND + 1))
    fi
fi
echo "aws_credentials=$AWS_CREDS"

# --- SSH private keys ---
SSH_KEYS="NO"
SSH_KEY_COUNT=0
if [ -d /root/.ssh ]; then
    for f in /root/.ssh/id_* /root/.ssh/*.pem; do
        if [ -f "$f" ]; then
            case "$f" in
                *.pub) ;; # skip public keys
                *)
                    SSH_KEY_COUNT=$((SSH_KEY_COUNT + 1))
                    ;;
            esac
        fi
    done
fi
if [ "$SSH_KEY_COUNT" -gt 0 ]; then
    SSH_KEYS="YES"
    CREDS_FOUND=$((CREDS_FOUND + 1))
fi
echo "ssh_private_keys=$SSH_KEYS"
echo "ssh_key_count=$SSH_KEY_COUNT"

# --- Kubernetes config ---
KUBE_CONFIG="NO"
if [ -f /root/.kube/config ]; then
    if grep -q "clusters\|certificate-authority" /root/.kube/config 2>/dev/null; then
        KUBE_CONFIG="YES"
        CREDS_FOUND=$((CREDS_FOUND + 1))
    fi
fi
echo "kube_config=$KUBE_CONFIG"

# --- GCP service account ---
GCP_CREDS="NO"
if [ -f /root/.config/gcloud/application_default_credentials.json ]; then
    if grep -q "client_id\|private_key" /root/.config/gcloud/application_default_credentials.json 2>/dev/null; then
        GCP_CREDS="YES"
        CREDS_FOUND=$((CREDS_FOUND + 1))
    fi
fi
echo "gcp_credentials=$GCP_CREDS"

# --- Git credentials ---
GIT_CREDS="NO"
if [ -f /root/.git-credentials ]; then
    if grep -q "https://\|http://" /root/.git-credentials 2>/dev/null; then
        GIT_CREDS="YES"
        CREDS_FOUND=$((CREDS_FOUND + 1))
    fi
fi
echo "git_credentials=$GIT_CREDS"

# --- Summary ---
echo "credentials_found=$CREDS_FOUND"

# --- Environment info ---
echo "probe_hostname=$(hostname)"
echo "probe_kernel=$(uname -r)"
