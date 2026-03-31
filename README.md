# AI Agent Security Labs

Hands-on labs to reproduce real-world AI agent security exploits and compare isolation strategies: **Docker containers** vs **micro-VMs** ([void-box](https://github.com/the-void-ia/void-box)).

These labs demonstrate why containers sharing a kernel with the host are insufficient for isolating autonomous AI agents, and how hardware-backed micro-VMs change the equation.

## Prerequisites

- Docker installed and running
- Linux host with root access (or macOS with Docker Desktop for labs 01-04)
- [void-box](https://github.com/the-void-ia/void-box) installed (for lab 05)
- Basic familiarity with shell scripting and containers

> **Warning:** Labs 02-04 demonstrate real container escape techniques. Run them only on disposable VMs or test machines. Never run them on production systems.

## Quickstart

```bash
git clone https://github.com/the-void-ia/ai-agent-security-labs.git
cd ai-agent-security-labs

# Run a specific lab
cd labs/01_prompt_injection
./exploit.sh
```

Each lab is self-contained. Read the lab's `README.md` for step-by-step instructions, then run `exploit.sh` and compare against `expected_output.md`.

## Labs

| # | Lab | What it demonstrates | Requires |
|---|-----|---------------------|----------|
| 01 | [Prompt Injection](labs/01_prompt_injection/) | Agent executes attacker-controlled input as instructions | Docker |
| 02 | [Docker Socket Escape](labs/02_docker_socket_escape/) | Mounted Docker socket gives full host access | Docker |
| 03 | [Privileged Container Escape](labs/03_privileged_container_escape/) | `--privileged` container mounts host disk | Docker + Linux |
| 04 | [Cgroup Escape](labs/04_cgroup_escape/) | cgroups v1 `release_agent` executes commands on host | Docker + Linux (cgroups v1) |
| 05 | [Void-Box Comparison](labs/05_void_box_comparison/) | Same exploits fail inside a micro-VM | Docker + void-box |

## Background

Autonomous AI agents (OpenClaw, Cline, Claude Code) need shell access, filesystem access, and API credentials to do useful work. When an agent is compromised via prompt injection or loses its safety constraints (the "confused deputy" problem), container isolation is the instinctive solution.

But containers share a kernel with the host. Labs 02-04 show three real escape paths that exploit this shared kernel:

1. **Docker socket** - mounting `/var/run/docker.sock` lets a container create sibling containers with full host access
2. **Privileged mode** - `--privileged` exposes host block devices, allowing direct disk mounting
3. **Cgroup v1 release_agent** - a kernel mechanism intended for resource cleanup becomes an escape vector

Void-box takes a different approach: each agent runs in its own KVM-backed micro-VM with its own kernel. The three escape paths above don't exist because there is no shared kernel, no Docker socket, and no host disk visible from the VM.

## Why Simulated Agents?

These labs use deterministic shell scripts to simulate agent behavior rather than running a real LLM. This is intentional:

- **Reproducibility matters.** LLM responses are non-deterministic — a prompt injection that works 70% of the time makes for a frustrating lab. Every exploit here succeeds on every run, on any machine.
- **The security proof is the same.** Whether an LLM generates `cat /etc/passwd` or a script does, the result is identical: untrusted input reaches a shell, and the container doesn't stop it. The exploits in labs 02-04 are infrastructure-level — they don't depend on model behavior at all.
- **Prompt injection is well-established.** The novel claim in this project isn't that agents can be tricked (that's [documented](https://adnanthekhan.com/posts/clinejection/) [extensively](https://www.aikido.dev/blog/promptpwnd-github-actions-ai-agents)). The claim is that containers don't contain the damage *after* the agent is compromised. That's what these labs prove.

## Project Structure

```
ai-agent-security-labs/
  README.md                              # This file
  labs/
    01_prompt_injection/
      README.md / exploit.sh / expected_output.md
    02_docker_socket_escape/
      README.md / exploit.sh / expected_output.md
    03_privileged_container_escape/
      README.md / exploit.sh / expected_output.md
    04_cgroup_escape/
      README.md / exploit.sh / expected_output.md
    05_void_box_comparison/
      README.md / exploit.sh / expected_output.md
```

## References

- [void-box](https://github.com/the-void-ia/void-box) - Micro-VM agent runtime
- [void-control](https://github.com/the-void-ia/void-control) - Control plane for void-box
- [CVE-2026-25253](https://nvd.nist.gov/vuln/detail/CVE-2026-25253) - OpenClaw WebSocket token theft (CVSS 8.8)
- [Clinejection](https://adnanthekhan.com/posts/clinejection/) - Prompt injection to supply chain attack
- [PromptPwnd](https://www.aikido.dev/blog/promptpwnd-github-actions-ai-agents) - AI agent prompt injection in GitHub Actions
- [Microsoft OpenClaw Advisory](https://www.microsoft.com/en-us/security/blog/2026/02/19/running-openclaw-safely-identity-isolation-runtime-risk/) - "Treat autonomous agents as untrusted code execution"

## License

Apache License 2.0 — see [LICENSE](LICENSE).
