# Lab 01: Prompt Injection

## Overview

Demonstrates how an AI agent executing inside a Docker container can be tricked into running arbitrary commands via prompt injection. The agent receives untrusted input (a simulated "GitHub issue title") that contains embedded instructions.

This reproduces the core mechanism behind the [Clinejection attack](https://adnanthekhan.com/posts/clinejection/), where a prompt injection in a GitHub issue title led to supply chain compromise of ~4,000 machines.

## What You'll Learn

- Prompt injection requires no special privileges or container misconfigurations
- The container boundary doesn't protect against prompt injection because the agent is *supposed* to run commands
- The agent faithfully executes attacker-controlled instructions because it can't distinguish them from legitimate ones

## Prerequisites

- Docker

## How It Works

1. A simulated AI agent runs inside a Docker container
2. The agent receives "user input" (an issue title) to classify
3. The input contains embedded instructions that override the agent's task
4. The agent executes the injected commands instead of classifying the issue

## Run

```bash
./exploit.sh
```

## What to Observe

- The agent was supposed to classify an issue as "bug" or "feature"
- Instead, it executed the injected command and exfiltrated environment variables
- The container boundary is irrelevant here: the agent has legitimate shell access and uses it as instructed by the attacker

## Mitigation

Prompt injection can't be fully solved at the container level. Defenses include:
- **Input validation**: sanitize untrusted input before it reaches the agent's prompt
- **Least privilege**: restrict what commands/tools the agent can use (void-box command allowlists)
- **Output filtering**: monitor agent actions for suspicious patterns
- **Isolated execution**: even if injected, limit blast radius via micro-VM isolation
