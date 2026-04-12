# AI Agent Security Labs

Hands-on labs to reproduce real-world AI agent security exploits and compare isolation strategies: **Docker containers** vs **micro-VMs** ([void-box](https://github.com/the-void-ia/void-box)).

These labs demonstrate why containers sharing a kernel with the host are insufficient for isolating autonomous AI agents, and how hardware-backed micro-VMs change the equation.

## Prerequisites

- Docker installed and running
- Linux host with root access (or macOS with Docker Desktop)
- [void-box](https://github.com/the-void-ia/void-box) installed (optional — each lab gracefully shows expected void-box behavior if not available)
- Basic familiarity with shell scripting and containers

> **Warning:** Labs 02-04 demonstrate real container escape techniques. Run them only on disposable VMs or test machines. Never run them on production systems.

## Quickstart

```bash
git clone https://github.com/the-void-ia/ai-agent-security-labs.git
cd ai-agent-security-labs

# Run all labs
./run_all.sh

# Or run a specific lab
cd labs/01_prompt_injection
./exploit.sh
```

Each lab is self-contained. Read the lab's `README.md` for step-by-step instructions, then run `exploit.sh` and compare against `expected_output.md`.

### Using a custom void-box build

If `voidbox` is not on your `PATH`, or you want to test a local build, point the labs at your binary and assets:

```bash
VOIDBOX_BIN=~/dev/repos/void-box/target/release/voidbox \
  VOID_BOX_KERNEL=~/dev/repos/void-box/target/vmlinux-arm64 \
  VOID_BOX_INITRAMFS=~/dev/repos/void-box/target/void-box-rootfs.cpio.gz \
  ./run_all.sh
```

The same env vars work with individual lab scripts (`./exploit.sh`). If none are set, labs fall back to the `voidbox` binary on `PATH` — and if that's not found either, void-box sections show expected behavior without running a VM.

## Labs

Each lab runs the exploit in Docker, then attempts the same thing in a void-box micro-VM to show the difference.

| # | Lab | What it demonstrates | Docker result | Void-Box result |
|---|-----|---------------------|---------------|-----------------|
| 01 | [Prompt Injection](labs/01_prompt_injection/) | Agent follows attacker-injected instructions | Secrets leaked, exfil possible | Nothing to steal |
| 02 | [Docker Socket Escape](labs/02_docker_socket_escape/) | Mounted Docker socket gives full host access | Full host control | No socket exists |
| 03 | [Privileged Container Escape](labs/03_privileged_container_escape/) | `--privileged` container mounts host disk | Host filesystem access | No host devices |
| 04 | [Cgroup Escape](labs/04_cgroup_escape/) | cgroups v1 `release_agent` executes on host | Root code exec on host | Guest kernel only |
| 05 | [Cloud Metadata SSRF](labs/05_metadata_ssrf/) | Default networking reaches cloud metadata service | IAM credentials stolen | Metadata unreachable |
| 06 | [Sensitive Mount Exfil](labs/06_sensitive_mount_exfil/) | Mounted credential dirs (`~/.aws`, `~/.ssh`, etc.) | All credentials readable | No host mounts |

## Architecture: Docker vs Void-Box

```
Docker Container:                    Void-Box Micro-VM:
┌──────────────┐                    ┌─────────────────┐
│  Container   │                    │  Guest VM       │
│  (process)   │                    │  (own kernel)   │
├──────────────┤                    ├─────────────────┤
│  Shared      │ ← escape here      │  Guest Kernel   │ ← isolated
│  Host Kernel │                    ├─────────────────┤
└──────────────┘                    │  VMM (KVM/VZ)   │
                                    ├─────────────────┤
                                    │  Host Kernel    │ ← not reachable
                                    └─────────────────┘
```

In Docker, an exploit in the container reaches the host kernel directly. In void-box, an exploit in the VM reaches the guest kernel — the host kernel is behind the hardware virtualization boundary.

### Void-Box Security Features

- **Hardware isolation**: Each agent runs in a KVM/VZ-backed micro-VM with its own kernel
- **Seccomp-BPF**: Syscall filtering even within the guest
- **Command allowlists**: Only declared commands can execute
- **Resource limits**: CPU and memory caps enforced by the VMM
- **SLIRP networking**: User-mode networking without host network access
- **vsock communication**: Point-to-point host-guest channel, no network stack
- **Declared capabilities**: Skills not mounted in the VM don't exist at runtime

## Background

Autonomous AI agents (OpenClaw, Cline, Claude Code) need shell access, filesystem access, and API credentials to do useful work. When an agent is compromised via prompt injection or loses its safety constraints (the "confused deputy" problem), container isolation is the instinctive solution.

But containers share a kernel with the host. Labs 02-04 show three real escape paths that exploit this shared kernel:

1. **Docker socket** - mounting `/var/run/docker.sock` lets a container create sibling containers with full host access
2. **Privileged mode** - `--privileged` exposes host block devices, allowing direct disk mounting
3. **Cgroup v1 release_agent** - a kernel mechanism intended for resource cleanup becomes an escape vector
4. **Cloud metadata SSRF** - if a container can reach the cloud metadata service, it can steal IAM credentials without any container escape
5. **Sensitive file mounts** - "convenience" volume mounts (`~/.aws`, `~/.ssh`, `~/.kube`) hand credentials directly to the agent

Lab 01 shows a different class of attack: **prompt injection** doesn't need any container misconfiguration — the agent uses its *legitimate* shell access to follow attacker instructions. Labs 05-06 show that even without container escapes, agents can steal credentials via cloud metadata services and mounted credential files.

Void-box takes a different approach: each agent runs in its own KVM-backed micro-VM with its own kernel. The container escape paths don't exist because there is no shared kernel, no Docker socket, and no host disk visible from the VM. And for prompt injection, the blast radius is near-zero because secrets aren't injected into the VM and network access is restricted.

## Why Simulated Agents?

These labs use deterministic shell scripts to simulate agent behavior rather than running a real LLM. This is intentional:

- **Reproducibility matters.** LLM responses are non-deterministic — a prompt injection that works 70% of the time makes for a frustrating lab. Every exploit here succeeds on every run, on any machine.
- **The security proof is the same.** Whether an LLM generates `cat /etc/passwd` or a script does, the result is identical: untrusted input reaches a shell, and the container doesn't stop it. The exploits in labs 02-04 are infrastructure-level — they don't depend on model behavior at all.
- **Prompt injection is well-established.** The novel claim in this project isn't that agents can be tricked (that's [documented](https://adnanthekhan.com/posts/clinejection/) [extensively](https://www.aikido.dev/blog/promptpwnd-github-actions-ai-agents)). The claim is that containers don't contain the damage *after* the agent is compromised. That's what these labs prove.

## Project Structure

```
ai-agent-security-labs/
  README.md                              # This file
  run_all.sh                             # Run all labs in sequence
  labs/
    lib/output.sh                        # Shared output helpers (colors, assertions)
    lib/voidbox.sh                       # Shared void-box helpers
    01_prompt_injection/
      exploit.sh / probe.sh / README.md / expected_output.md
    02_docker_socket_escape/
      exploit.sh / probe.sh / README.md / expected_output.md
    03_privileged_container_escape/
      exploit.sh / probe.sh / README.md / expected_output.md
    04_cgroup_escape/
      exploit.sh / probe.sh / README.md / expected_output.md
    05_metadata_ssrf/
      exploit.sh / probe.sh / README.md / expected_output.md
    06_sensitive_mount_exfil/
      exploit.sh / probe.sh / README.md / expected_output.md
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
