# Lab 05: Cloud Metadata Service SSRF

## Overview

Demonstrates how a container with **default networking** (no `--privileged`, no special capabilities) can reach the cloud instance metadata service at `169.254.169.254`, stealing IAM credentials, instance identity, and user-data bootstrap secrets.

Then shows that Docker **can** mitigate this with explicit network isolation — but the default is vulnerable. Void-box blocks it by default because SLIRP networking doesn't route link-local addresses.

**The lesson**: The attack surface is the same in both systems. The difference is in the defaults — Docker requires opt-in mitigation, void-box is safe out of the box.

## What You'll Learn

- The cloud metadata service is reachable from any container with default Docker networking on a cloud VM
- IAM credentials attached to the host VM are accessible to every container on that host
- User-data scripts often contain hardcoded secrets (database passwords, deploy keys)
- **Docker can block this** — with network isolation, iptables rules, or IMDSv2 hop-limit=1
- **Void-box blocks this by default** — SLIRP networking cannot reach link-local addresses
- The difference is in defaults, not capability

## Prerequisites

- Docker
- void-box (optional — expected behavior shown if not available)

## How It Works

1. A mock metadata service starts at `169.254.169.254` on a Docker network (simulating the real cloud endpoint)
2. **Docker (default)**: agent container on the same network reaches the metadata endpoint and steals IAM credentials
3. **Docker (isolated)**: agent container on an internal network cannot reach the metadata endpoint
4. **Void-box**: agent in a micro-VM cannot reach the metadata endpoint (SLIRP blocks link-local by default)

## Run

```bash
./exploit.sh
```

## What to Observe

- **Docker (default)**: metadata reachable, IAM credentials stolen, user-data exposed — 4/4 assertions pass
- **Docker (isolated)**: metadata unreachable, no credentials stolen — mitigation works
- **Void-Box**: metadata unreachable by default — no explicit mitigation needed
- The summary table shows three columns: Docker default (vulnerable), Docker mitigated (safe), void-box (safe by default)

## Fair Comparison

This lab uses a mock metadata service to simulate the cloud endpoint. On a real cloud VM:

- **Docker default networking** routes to `169.254.169.254` — containers can reach it without any special flags
- **Docker with `--net=internal`** or iptables rules blocks the route — but requires explicit configuration
- **Void-box SLIRP networking** does not route link-local addresses — blocked without any configuration

Both Docker and void-box can block this attack. The difference is that Docker requires the developer to know about the risk and explicitly mitigate it, while void-box blocks it by default.

## Mitigations

- **IMDSv2 with hop-limit=1**: AWS Instance Metadata Service v2 requires a token obtained via PUT request with a TTL hop limit. Setting `HttpPutResponseHopLimit=1` prevents containers (which add a network hop) from reaching the service. **This is the single most effective fix.**
- **iptables rules on the host**: Block container access to `169.254.169.254` via host iptables rules. Effective but requires manual setup and is easy to miss.
- **Network policy enforcement**: In Kubernetes, use NetworkPolicy to block egress to `169.254.169.254/32`.
- **`docker network create --internal`**: Create internal-only Docker networks that don't route externally.
- **Disable instance metadata**: If the VM doesn't need instance metadata, disable it entirely.
- **Micro-VM isolation (void-box)**: SLIRP networking provides a user-mode network stack that doesn't route to link-local addresses. No configuration needed.
- **Least-privilege IAM roles**: Minimize the permissions attached to the VM's IAM role. Even if credentials are stolen, limit what the attacker can do.
