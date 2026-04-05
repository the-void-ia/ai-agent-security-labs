# Lab 02: Docker Socket Escape

## Overview

Demonstrates how mounting the Docker socket (`/var/run/docker.sock`) inside a container gives the container full control over the host. Many agent setups do this so the agent can orchestrate containers — but it's equivalent to giving root access to the host.

## What You'll Learn

- Mounting the Docker socket lets a container create sibling containers with arbitrary host mounts
- A compromised agent can read and write the entire host filesystem via sibling containers
- This is not a bug — it's how Docker works by design
- Void-box eliminates the attack surface entirely: no Docker socket, no daemon, no escape path

## Prerequisites

- Docker
- void-box (optional — expected behavior shown if not available)

## How It Works

1. An "agent container" starts with the Docker socket mounted (common in CI/CD and orchestration setups)
2. From inside the container, the agent queries the host Docker daemon
3. The agent creates a sibling container that mounts the host's `/etc` — reads `/etc/passwd` and `/etc/hostname`
4. The agent creates another sibling that mounts host `/tmp` — writes and verifies a proof file
5. The same probe runs in void-box, where all Docker-dependent checks fail (no socket, no CLI, no daemon)

## Run

```bash
./exploit.sh
```

## What to Observe

- **The agent's container appeared isolated** — its own hostname, kernel, filesystem
- **The Docker socket is a direct gateway to the host** — it gives full control over the Docker daemon
- **Sibling containers break the isolation** — the agent creates containers that mount host paths, reading and writing host files from within the "isolated" container
- **Write access is proven** — a proof file is created on the host's `/tmp`, confirming the escape is bidirectional
- **Full escalation is one command away** — `docker run --privileged -v /:/host alpine chroot /host bash`
- **Docker assertions verify**: socket accessible, daemon reachable, host files readable, host files writable (4/4)
- **Void-Box assertions verify**: no socket, no CLI, no daemon, no read/write capability, different kernel

## Why This Matters for AI Agents

Agent frameworks sometimes mount the Docker socket so the agent can:
- Create isolated environments for code execution
- Manage containers as part of a workflow
- Run tools in separate containers

Each of these use cases gives the agent the ability to escape its container entirely.

## Mitigation

- **Never mount the Docker socket** inside agent containers
- Use Docker-in-Docker (dind) with limited privileges instead
- Or use micro-VMs (void-box) where there is no Docker socket to mount — the attack surface doesn't exist
