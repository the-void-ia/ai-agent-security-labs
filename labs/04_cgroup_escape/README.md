# Lab 04: Cgroup Escape

## Overview

Demonstrates how a container with `CAP_SYS_ADMIN` can use the cgroups v1 `release_agent` mechanism to execute arbitrary commands **on the host** with root privileges. The command runs outside the container entirely.

This is the most sophisticated of the container escape techniques. It doesn't just read host files — it executes code on the host as root.

## What You'll Learn

- The cgroups v1 `release_agent` is a kernel feature intended for resource cleanup
- When combined with `CAP_SYS_ADMIN`, it becomes an escape vector — arbitrary code execution as root on the host
- The container's process isolation is completely bypassed
- cgroups v2 removed the `release_agent` mechanism (but many production systems still use v1)
- Void-box is immune regardless of cgroup version: the VM has its own kernel, so release_agent targets the guest, not the host

## Prerequisites

- Docker
- For a successful exploit: **Linux host with cgroups v1** and `CAP_SYS_ADMIN`
- On cgroups v2 (Docker Desktop, modern distros): the exploit fails — the script explains why
- void-box (optional — expected behavior shown if not available)

## How It Works

1. Container mounts a cgroups v1 subsystem and creates a new cgroup
2. Container enables `notify_on_release` and sets `release_agent` to a script path
3. The path is resolved on the **host** filesystem (via the container's overlay mount)
4. Container triggers the release by adding and removing a process from the cgroup
5. The **host kernel** executes the release agent script — outside the container, as root

## Run

```bash
./exploit.sh
```

## What to Observe

**On cgroups v2 (Docker Desktop, modern Linux):**

- The script attempts the exploit and shows exactly where it fails (cgroup v1 mount)
- Explains why: cgroups v2 removed the `release_agent` mechanism
- Walks through the full attack chain so you understand the technique
- Assertions verify the exploit is correctly blocked

**On cgroups v1 (older Linux hosts):**

- The exploit succeeds — a script is executed on the host as root
- The output file contains the host's hostname, kernel, and process list
- Compare these with the container's own hostname/kernel to confirm the escape
- Assertions verify v1 mount and release_agent write succeeded

**Void-Box (any cgroup version):**

- The VM has its own kernel with its own cgroup hierarchy
- Even if cgroups v1 were present, `release_agent` would execute inside the guest kernel, not on the host
- Assertions verify different kernel from host (proving hardware boundary)

## Mitigation

- Never grant `CAP_SYS_ADMIN` to agent containers
- Use cgroups v2 (not vulnerable to `release_agent` escape)
- Use `--security-opt apparmor=docker-default`
- Or use micro-VMs (void-box) where guest cgroups operate within the guest kernel — even a successful exploit stays contained
