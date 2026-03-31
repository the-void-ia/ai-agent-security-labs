# AGENTS.md — AI Agent Security Labs

Hands-on labs reproducing real-world AI agent security exploits (container escapes,
prompt injection) and comparing Docker container isolation vs void-box micro-VM
isolation. This file covers project structure, conventions, and testing guidance
for agents working on the project.

## Project structure

```
ai-agent-security-labs/
  README.md                     # Project overview, quickstart, labs table
  AGENTS.md                     # This file (agent guidelines)
  CLAUDE.md                     # Claude Code specific guidance
  .gitignore
  labs/
    01_prompt_injection/        # Prompt injection via unsanitized input
    02_docker_socket_escape/    # Escape via mounted Docker socket
    03_privileged_container_escape/  # Escape via --privileged disk mount
    04_cgroup_escape/           # Escape via cgroups v1 release_agent
    05_void_box_comparison/     # Same exploits fail in void-box micro-VM
```

Each lab contains:
- `README.md` — step-by-step instructions and what to observe
- `exploit.sh` — self-contained, runnable exploit script
- `expected_output.md` — reference output for comparison

## Conventions

### Shell scripts

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Scripts must be self-contained — no external dependencies beyond Docker (and
  optionally void-box for lab 05).
- Scripts must clean up after themselves (remove proof files, unmount, etc.).
- Output follows a consistent format:
  - `[Host]` prefix for host baseline info
  - `[*]` for informational steps
  - `[!]` for exploit results / evidence
  - `[Docker]` / `[Void-Box]` for environment-specific output
- Show environment info (hostname, kernel) to make isolation boundaries visible.

### Lab design principles

- **Deterministic**: Labs use shell scripts, not real LLMs, for reproducibility.
  Prompt injection (lab 01) simulates the agent's behavior because LLM outputs
  are non-deterministic — the security proof is the same either way.
- **Evidence-based**: Each exploit shows concrete proof (host files read, host
  processes listed, different kernels visible) rather than just pass/fail labels.
- **Side-by-side comparison**: Lab 05 runs the same checks in Docker and void-box
  to make the isolation difference visible.
- **Graceful degradation**: Scripts handle platform differences (macOS vs Linux,
  cgroups v1 vs v2) and explain what would happen on the target platform.

### Void-box integration (lab 05)

Lab 05 uses `kind: workflow` specs (raw shell commands inside a micro-VM) instead
of `kind: agent` — no LLM provider or API keys required.

The `VOIDBOX_BIN` env var overrides the voidbox binary path. When using a local
build, also set `VOID_BOX_KERNEL` and `VOID_BOX_INITRAMFS`:

```bash
VOIDBOX_BIN=~/dev/repos/void-box/target/release/voidbox \
VOID_BOX_KERNEL=~/dev/repos/void-box/target/vmlinux-arm64 \
VOID_BOX_INITRAMFS=~/dev/repos/void-box/target/void-box-rootfs.cpio.gz \
./exploit.sh
```

VM memory must be >= 1024MB (the initramfs is ~277MB uncompressed; 256MB causes
vsock module to fail to load).

## Testing

Run each lab individually:

```bash
cd labs/01_prompt_injection && ./exploit.sh
cd labs/02_docker_socket_escape && ./exploit.sh
cd labs/03_privileged_container_escape && ./exploit.sh
cd labs/04_cgroup_escape && ./exploit.sh
cd labs/05_void_box_comparison && ./exploit.sh  # requires voidbox
```

Labs 01-04 require only Docker. Lab 05 requires void-box (falls back to
Docker-only with explanatory text if voidbox is not available).

Lab 04 (cgroup escape) requires cgroups v1 + `CAP_SYS_ADMIN` for the full
exploit — on cgroups v2 (Docker Desktop, modern Linux) it explains why the
exploit fails.

## Related projects

- [void-box](https://github.com/the-void-ia/void-box) — Micro-VM agent runtime
- [void-control](https://github.com/the-void-ia/void-control) — Control plane for void-box
