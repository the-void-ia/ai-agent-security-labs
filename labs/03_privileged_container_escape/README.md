# Lab 03: Privileged Container Escape

## Overview

Demonstrates how a container running with `--privileged` (or `--cap-add=SYS_ADMIN`) can mount the host's disk and gain full filesystem access. Some agent setups use privileged mode to simplify device access or avoid permission issues.

## What You'll Learn

- `--privileged` exposes all host devices (`/dev/sda`, `/dev/nvme0n1`, etc.) to the container
- The container can mount these devices and access the host's entire filesystem
- Even `--cap-add=SYS_ADMIN` alone (without full `--privileged`) is enough

## Prerequisites

- Docker
- **Linux host** (block devices are not exposed on Docker Desktop for macOS/Windows)

## How It Works

1. A container starts with `--privileged`
2. Inside the container, `fdisk -l` shows the host's physical disks
3. The container mounts the host's root partition
4. Full read/write access to the host filesystem

## Run

```bash
./exploit.sh
```

> **Note:** On macOS with Docker Desktop, this lab runs inside the Docker VM, not your Mac. The script detects this and adjusts accordingly.

## What to Observe

- `fdisk -l` output shows the host's real block devices
- The host's root filesystem is mounted inside the container
- `/etc/shadow`, `/root/.ssh/`, and other sensitive files are accessible

## Mitigation

- **Never use `--privileged`** for agent containers
- Drop all capabilities and add only what's strictly needed
- Use `--security-opt=no-new-privileges`
- Or use micro-VMs (void-box) where the guest has its own kernel and no access to host devices
