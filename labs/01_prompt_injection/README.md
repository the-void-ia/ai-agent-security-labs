# Lab 01: Prompt Injection

## Overview

Demonstrates how an AI agent executing inside a Docker container can be hijacked via prompt injection — attacker-controlled text embedded in untrusted input (a GitHub issue title) that the LLM interprets as instructions.

This reproduces the core mechanism behind the [Clinejection attack](https://adnanthekhan.com/posts/clinejection/): prompt injection in a GitHub issue title steering an agent into dangerous tool use, which later chained into a broader release-token compromise and unauthorized package publication.

**Key distinction**: This is *not* shell command injection (unsanitized input passed to `eval`). It's prompt injection — the LLM cannot distinguish the developer's system prompt from the attacker's text injected into the data. The agent uses its *legitimate* shell access to execute what the LLM decides, which is now under attacker control.

## What You'll Learn

- Prompt injection requires no special privileges, container misconfigurations, or shell metacharacters
- The container boundary doesn't protect against prompt injection because the agent is *designed* to run commands — the LLM just runs the wrong ones
- LLMs can't reliably distinguish instructions from data — an attacker's text in the context window competes with the developer's system prompt
- Exfiltration is trivial once the agent is hijacked: it already has network and shell access
- Void-box reduces the blast radius to near-zero: no secrets, restricted network, command allowlists

## Prerequisites

- Docker
- void-box (optional — expected behavior shown if not available)

## How It Works

1. A simulated AI agent runs inside a Docker container with shell tool access
2. The agent receives a "GitHub issue title" to classify as `bug` or `feature`
3. The issue title contains natural-language instructions: *"IGNORE PREVIOUS INSTRUCTIONS..."*
4. The LLM follows the injected instructions (simulated) instead of classifying the issue
5. The agent reads sensitive files, dumps environment variables, and prepares exfiltration
6. The same scenario runs in a void-box micro-VM — the injection still works, but there's nothing to steal

## Run

```bash
./exploit.sh
```

## What to Observe

- **The agent's task was simple**: output "bug" or "feature" — it didn't need shell access for this
- **The injected instructions won**: the LLM followed "IGNORE PREVIOUS INSTRUCTIONS" over its system prompt
- **The agent used its own tools against itself**: no exploit code, no shell tricks — just the agent's legitimate `sh` tool
- **Docker**: all secrets visible, exfiltration tools available, full network access
- **Void-Box**: no secrets in env, network restricted (SLIRP), no curl (wget present via busybox but no secrets to exfiltrate) — blast radius is near zero
- **Assertions verify the claims**: Docker asserts secrets *are* found (>= 4); void-box asserts secrets are *not* found (0). If either side regresses, the output says `[FAIL]`

## Why Containers Don't Help

| Defense | Helps? | Why not |
|---|---|---|
| `--read-only` filesystem | No | Agent can still read secrets from env vars and exfiltrate via network |
| Dropped capabilities | No | Agent doesn't need special capabilities to run `curl` or read env |
| `--no-new-privileges` | No | Agent already has the only privilege it needs: shell access |
| Network isolation | Partially | Blocks exfiltration, but also blocks the agent's legitimate work |
| seccomp/AppArmor | No | Agent uses allowed syscalls (read, write, connect) |

## Mitigations

Prompt injection cannot be fully solved by container hardening. Effective defenses operate at the LLM and application layer:

- **Input/output boundary enforcement**: Clearly separate untrusted data from instructions using structured formats (e.g., XML tags, tool-use schemas) rather than concatenating user input into prompts
- **Least-privilege tool access**: Don't give the agent shell access when it only needs to output a label. Use structured tool-use APIs with explicit allowlists instead of raw `sh`
- **Human-in-the-loop for sensitive operations**: Require human approval before the agent executes commands that access secrets, make network requests, or modify files
- **Output filtering / behavioral monitoring**: Detect when agent actions deviate from its expected behavior (e.g., a classification agent running `cat /etc/passwd`)
- **Micro-VM isolation (void-box)**: Even if injected, contain the blast radius — the agent runs in a VM with no access to host secrets, network restrictions, and command allowlists
- **Secret management**: Don't pass secrets as environment variables accessible to the agent. Use a secrets manager with scoped, just-in-time access
