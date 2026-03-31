# Lab 02: Docker Socket Escape

## Overview

Demonstrates how mounting the Docker socket (`/var/run/docker.sock`) inside a container gives the container full control over the host. Many agent setups do this so the agent can orchestrate containers — but it's equivalent to giving root access to the host.

## What You'll Learn

- Mounting the Docker socket lets a container create sibling containers with arbitrary host mounts
- A compromised agent can use this to access the entire host filesystem
- This is not a bug — it's how Docker works by design

## Prerequisites

- Docker

## How It Works

1. An "agent container" starts with the Docker socket mounted (common in CI/CD and orchestration setups)
2. From inside the container, the agent uses the Docker socket to create a new container
3. The new container mounts the host's root filesystem at `/host`
4. The agent now has full read/write access to the host

## Run

```bash
./exploit.sh
```

## What to Observe

- The script runs inside a container that appears isolated
- Using the Docker socket, it creates a sibling container that mounts the host's `/etc` and `/root`
- It reads `/etc/hostname` and lists SSH keys from the host
- The original container seemed isolated, but the Docker socket is a direct gateway to the host

## Why This Matters for AI Agents

Agent frameworks sometimes mount the Docker socket so the agent can:
- Create isolated environments for code execution
- Manage containers as part of a workflow
- Run tools in separate containers

Each of these use cases gives the agent the ability to escape its container entirely.

## Mitigation

- **Never mount the Docker socket** inside agent containers
- Use Docker-in-Docker (dind) with limited privileges instead
- Or use micro-VMs (void-box) where there is no Docker socket to mount
