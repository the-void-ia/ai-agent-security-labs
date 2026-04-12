#!/bin/sh
# Lab 03: Privileged Container Escape probe
#
# Runs inside BOTH Docker (--privileged) and void-box to compare
# escape capability. Outputs structured key=value pairs for assertions.
#
# In Docker (--privileged): host block devices visible, mountable,
# host filesystem readable.
# In void-box: no host devices, mount fails, no host data accessible.

# --- Host block devices visible? ---
DEVS=$(fdisk -l 2>/dev/null | grep "^Disk /dev/" | head -5)
DEV_COUNT=$(echo "$DEVS" | grep -c "^Disk" 2>/dev/null || echo 0)
if [ "$DEV_COUNT" -gt 0 ] 2>/dev/null; then
    echo "block_devices_visible=YES"
    echo "block_device_count=$DEV_COUNT"
else
    echo "block_devices_visible=NO"
    echo "block_device_count=0"
fi

# --- Find a mountable partition ---
ROOT_DEV=""
PARTITION_CANDIDATES=$(awk 'NR > 2 { print $4 }' /proc/partitions 2>/dev/null \
    | grep -E '([0-9]$|p[0-9]+$)' \
    | grep -Ev '^(loop|ram|fd|sr|md)')
for part in $PARTITION_CANDIDATES; do
    if [ -b "/dev/$part" ]; then
        ROOT_DEV="/dev/$part"
        break
    fi
done
echo "mountable_partition=$ROOT_DEV"

# --- Can mount host disk? ---
CAN_MOUNT="NO"
MOUNTED_PATH=""
if [ -n "$ROOT_DEV" ]; then
    mkdir -p /mnt/host_probe 2>/dev/null || true
    if mount -o ro "$ROOT_DEV" /mnt/host_probe 2>/dev/null; then
        CAN_MOUNT="YES"
        MOUNTED_PATH="/mnt/host_probe"
    fi
fi
echo "can_mount_host_disk=$CAN_MOUNT"

# --- Can read host files? ---
CAN_READ_HOSTNAME="NO"
HOST_HOSTNAME="none"
CAN_READ_SHADOW="NO"
CAN_READ_DOCKER="NO"
DOCKER_LAYER_COUNT=0

if [ -n "$MOUNTED_PATH" ]; then
    # hostname
    if [ -f "$MOUNTED_PATH/etc/hostname" ]; then
        HOST_HOSTNAME=$(cat "$MOUNTED_PATH/etc/hostname" | tr -d '[:space:]')
        CAN_READ_HOSTNAME="YES"
    fi

    # shadow (sensitive credential file)
    if [ -f "$MOUNTED_PATH/etc/shadow" ]; then
        CAN_READ_SHADOW="YES"
    fi

    # Docker data (other containers' filesystems)
    # Docker Desktop: /docker/containers/  Native Linux: /var/lib/docker/containers/
    DOCKER_DATA_DIR=""
    for ddir in "$MOUNTED_PATH/docker" "$MOUNTED_PATH/var/lib/docker"; do
        if [ -d "$ddir/containers" ]; then
            DOCKER_DATA_DIR="$ddir"
            break
        fi
    done
    if [ -n "$DOCKER_DATA_DIR" ]; then
        CAN_READ_DOCKER="YES"
        DOCKER_LAYER_COUNT=$(ls "$DOCKER_DATA_DIR/containers/" 2>/dev/null | wc -l | tr -d " ")
    fi

    umount "$MOUNTED_PATH" 2>/dev/null || true
fi

echo "can_read_hostname=$CAN_READ_HOSTNAME"
echo "host_hostname=$HOST_HOSTNAME"
echo "can_read_shadow=$CAN_READ_SHADOW"
echo "can_read_docker_data=$CAN_READ_DOCKER"
echo "docker_layer_count=$DOCKER_LAYER_COUNT"

# --- Environment info ---
echo "probe_hostname=$(hostname)"
echo "probe_kernel=$(uname -r)"
