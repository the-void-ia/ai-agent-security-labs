# Lab 05: Cloud Metadata Service SSRF

## Overview

Demonstrates the cloud metadata credential-theft path using a mock service bound to `169.254.169.254` on a dedicated Docker network. This simulates the real cloud condition where a container can reach the instance metadata service and steal IAM credentials, instance identity, and user-data bootstrap secrets.

Then shows that Docker **can** mitigate this with explicit network isolation once metadata reachability exists. Void-box blocks link-local metadata access by default because SLIRP networking doesn't route those addresses.

**The lesson**: The attack surface is the same in both systems. The difference is in the defaults — Docker requires opt-in mitigation, void-box is safe out of the box.

## What You'll Learn

- The cloud metadata service becomes a credential theft vector whenever a container can reach `169.254.169.254`
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
2. **Docker (simulated vulnerable cloud path)**: agent container on the same network reaches the metadata endpoint and steals IAM credentials
3. **Docker (isolated)**: agent container on an internal network cannot reach the metadata endpoint
4. **Void-box**: agent in a micro-VM cannot reach the metadata endpoint (SLIRP blocks link-local by default)

## Run

```bash
./exploit.sh
```

## What to Observe

- **Docker (simulated vulnerable cloud path)**: metadata reachable, IAM credentials stolen, user-data exposed — 4/4 assertions pass
- **Docker (isolated)**: metadata unreachable, no credentials stolen — mitigation works
- **Void-Box**: metadata unreachable by default — no explicit mitigation needed
- The summary table shows three columns: simulated vulnerable Docker, mitigated Docker, and void-box default behavior

## Fair Comparison

This lab uses a mock metadata service to simulate the cloud endpoint. On a real cloud VM:

- **The first Docker scenario** simulates a vulnerable cloud setup by placing a mock service at `169.254.169.254` on a Docker network
- **Docker with `--net=internal`** or iptables rules blocks the route — but requires explicit configuration
- **Void-box SLIRP networking** does not route link-local addresses — blocked without any configuration

Both Docker and void-box can block this attack. The difference is that Docker requires the developer to know about the risk and explicitly mitigate it, while void-box blocks link-local metadata access by default.

## Mitigations

- **IMDSv2 with hop-limit=1**: AWS Instance Metadata Service v2 requires a token obtained via PUT request with a TTL hop limit. Setting `HttpPutResponseHopLimit=1` prevents containers (which add a network hop) from reaching the service. **This is the single most effective fix.**
- **iptables rules on the host**: Block container access to `169.254.169.254` via host iptables rules. Effective but requires manual setup and is easy to miss.
- **Network policy enforcement**: In Kubernetes, use NetworkPolicy to block egress to `169.254.169.254/32`.
- **`docker network create --internal`**: Create internal-only Docker networks that don't route externally.
- **Disable instance metadata**: If the VM doesn't need instance metadata, disable it entirely.
- **Micro-VM isolation (void-box)**: SLIRP networking provides a user-mode network stack that doesn't route to link-local addresses. No configuration needed.
- **Least-privilege IAM roles**: Minimize the permissions attached to the VM's IAM role. Even if credentials are stolen, limit what the attacker can do.
