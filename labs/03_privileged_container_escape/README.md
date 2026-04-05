# Lab 03: Privileged Container Escape

## Overview

Demonstrates how a container running with `--privileged` (or `--cap-add=SYS_ADMIN`) can mount the host's disk and gain full filesystem access. Some agent setups use privileged mode to simplify device access or avoid permission issues.

## What You'll Learn

- `--privileged` exposes all host block devices (`/dev/sda`, `/dev/vda`, etc.) to the container
- The container can mount these devices and access the host's entire filesystem
- On Docker Desktop, this includes all other containers' data (Docker data directory)
- Even `--cap-add=SYS_ADMIN` alone (without full `--privileged`) is enough
- Void-box eliminates the attack surface: the VM has its own kernel, no host devices visible

## Prerequisites

- Docker
- void-box (optional — expected behavior shown if not available)

> **Note:** On macOS with Docker Desktop, the "host" is the Docker VM, not your Mac. The exploit still works — it escapes into the Docker VM and accesses Docker's internal data (all containers' filesystems, volumes, etc.).

## How It Works

1. A container starts with `--privileged` (simulating an agent that needs device access)
2. Inside the container, `fdisk -l` reveals the host's physical block devices
3. The container mounts the host's root partition at `/mnt/host`
4. The container reads host files: `/etc/hostname`, `/etc/shadow`, Docker data, SSH keys
5. The same probe runs in void-box — no devices visible, no mount possible, no host data

## Run

```bash
./exploit.sh
```

## What to Observe

- **Block devices exposed**: `fdisk -l` shows real host disks that a container should never see
- **Host disk mounted**: The container mounts `/dev/vda1` (or `/dev/sda1`) and gains full access
- **Sensitive data readable**: `/etc/shadow` (password hashes), SSH keys, Docker data directory
- **Docker data = all containers**: On Docker Desktop, the mounted disk contains all containers' filesystems, meaning one privileged container can read every other container's data
- **Docker assertions verify**: devices visible, disk mounted, host files readable
- **Void-Box assertions verify**: no devices, no mount, no host files, different kernel

## Mitigation

- **Never use `--privileged`** for agent containers
- Drop all capabilities and add only what's strictly needed
- Use `--security-opt=no-new-privileges`
- Or use micro-VMs (void-box) where the guest has its own kernel and no access to host devices — the attack surface doesn't exist
