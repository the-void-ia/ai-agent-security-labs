# Lab 06: Sensitive File Mount Exfiltration

## Overview

Demonstrates how Docker's permissive mount model leads to credential oversharing. A developer who wants an agent to push code to GitHub mounts several convenience credential paths (`~/.ssh`, `~/.aws`, `~/.kube`, `~/.config/gcloud`) and exposes far more than the agent actually needs.

Then shows that Docker **can** be used safely with targeted mounts (only `.git-credentials`), and that void-box starts from a deny-by-default baseline through its explicit declaration model.

**The lesson**: Docker and void-box can both limit credential access. The difference is in which mistake is easier to make — Docker's broad mounts are the path of least resistance, while void-box requires explicit declarations for every file.

## What You'll Learn

- Mounting credential directories for convenience gives the agent access to every credential on the host
- No container escape needed — the secrets are *inside* the container by design
- **Docker can prevent this** — with targeted single-file mounts instead of directory mounts
- **Void-box prevents this by default** — nothing is accessible unless declared in the workflow spec
- The difference is not in capability but in the default behavior and guardrails
- Read-only mounts (`:ro`) don't help — the agent can still read and exfiltrate credentials

## Prerequisites

- Docker
- void-box (optional — expected behavior shown if not available)

## How It Works

1. Mock credential files are created (simulating a developer's home directory)
2. **Docker (broad mounts)**: all credential directories mounted — agent finds 5 credential types
3. **Docker (targeted mount)**: only `.git-credentials` mounted — agent finds only what it needs
4. **Void-box**: no files declared in workflow spec — agent finds nothing until the developer explicitly opts in

## Credential Files Tested

| Path | Contents | Needed for git push? |
|---|---|---|
| `~/.aws/credentials` | AWS access keys (2 profiles) | No |
| `~/.ssh/id_ed25519` | SSH private key + bastion config | No |
| `~/.kube/config` | Kubernetes cluster + service token | No |
| `~/.config/gcloud/` | GCP application default credentials | No |
| `~/.git-credentials` | GitHub + GitLab PATs | **Yes** |

## Run

```bash
./exploit.sh
```

## What to Observe

- **Docker (broad mounts)**: all 5 credential types found — agent needed 1, got 5
- **Docker (targeted mount)**: only git credentials found — the safe approach
- **Void-Box**: 0 credentials found — nothing declared in workflow spec
- **The summary table shows three columns**, making the honest comparison visible
- Docker targeted and void-box both avoid oversharing, but the lab's void-box section demonstrates the stricter deny-by-default starting point

## Fair Comparison

This lab does **not** claim that Docker is inherently insecure for credential management. A careful developer who mounts only `.git-credentials` can avoid oversharing too.

The difference is structural:

- **Docker**: nothing prevents `docker run -v ~/.ssh:/root/.ssh -v ~/.aws:/root/.aws ...`. The broad mount and the targeted mount are equally easy to write. There's no review step, no audit trail, no guardrail.
- **Void-box**: the developer writes a workflow spec that explicitly declares every file. The spec is version-controlled and auditable. You can't accidentally mount `~/.aws` when you meant to mount `.git-credentials`.

The attack here is not a Docker vulnerability — it's a human error that Docker's model makes easy and void-box's model makes hard.

## Mitigations

- **Mount individual files, not directories**: `docker run -v ~/.git-credentials:/root/.git-credentials:ro` instead of `docker run -v ~/:/root:ro`
- **Audit `docker run` and `docker-compose.yml` for credential paths**: Search for `-v` flags that reference `~/.aws`, `~/.ssh`, `~/.kube`, or similar. This is the lowest-effort check with the highest payoff
- **Use credential helpers instead of files**: Use `aws-vault`, `gcloud auth`, or SSH agent forwarding instead of mounting raw credential files
- **Secrets manager with scoped access**: Use Vault, AWS Secrets Manager, or similar to provide short-lived, narrowly-scoped credentials
- **Micro-VM with explicit declarations (void-box)**: The workflow spec declares every file the agent can access. The spec is auditable and version-controlled — oversharing requires an explicit decision, not an oversight
