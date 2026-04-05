#!/bin/sh
# Lab 04: Cgroup Escape probe
#
# Runs inside BOTH Docker (with CAP_SYS_ADMIN) and void-box to compare
# escape capability. Outputs structured key=value pairs for assertions.
#
# In Docker on cgroups v1: mount succeeds, release_agent writable, code runs on host.
# In Docker on cgroups v2: mount fails — v2 removed release_agent mechanism.
# In void-box: even if release_agent worked, it targets the guest kernel only.

# --- Cgroups version ---
CGROUP_VERSION="unknown"
if mount | grep -q "cgroup2" 2>/dev/null; then
    CGROUP_VERSION="v2"
elif [ -d /sys/fs/cgroup/cpu ]; then
    CGROUP_VERSION="v1"
fi
echo "cgroup_version=$CGROUP_VERSION"

# --- CAP_SYS_ADMIN present? ---
# Check by attempting a privileged mount (the actual test for this exploit)
CAN_MOUNT_CGROUP="NO"
mkdir -p /tmp/cgrp_probe 2>/dev/null || true
if mount -t cgroup -o rdma cgroup /tmp/cgrp_probe 2>/dev/null; then
    CAN_MOUNT_CGROUP="YES"
    umount /tmp/cgrp_probe 2>/dev/null || true
fi
rmdir /tmp/cgrp_probe 2>/dev/null || true
echo "can_mount_cgroupv1=$CAN_MOUNT_CGROUP"

# --- release_agent writable? (only meaningful on v1 with successful mount) ---
RELEASE_AGENT_WRITABLE="NO"
if [ "$CAN_MOUNT_CGROUP" = "YES" ]; then
    mkdir -p /tmp/cgrp_probe2 2>/dev/null || true
    if mount -t cgroup -o rdma cgroup /tmp/cgrp_probe2 2>/dev/null; then
        if [ -f /tmp/cgrp_probe2/release_agent ]; then
            # Try to write (dry run — write empty string to test permissions)
            if echo "" > /tmp/cgrp_probe2/release_agent 2>/dev/null; then
                RELEASE_AGENT_WRITABLE="YES"
            fi
        fi
        umount /tmp/cgrp_probe2 2>/dev/null || true
    fi
    rmdir /tmp/cgrp_probe2 2>/dev/null || true
fi
echo "release_agent_writable=$RELEASE_AGENT_WRITABLE"

# --- Would release_agent target host or guest kernel? ---
# In Docker: release_agent runs in the host kernel (shared kernel)
# In void-box: release_agent would run in the guest kernel (own kernel)
# We can't distinguish this from inside — this is an architectural property.
# The probe just reports the kernel for comparison.
echo "probe_hostname=$(hostname)"
echo "probe_kernel=$(uname -r)"
