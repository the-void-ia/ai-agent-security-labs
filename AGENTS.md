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
  run_all.sh                    # Run all labs in sequence
  .gitignore
  labs/
    lib/output.sh               # Shared output helpers (colors, assertions, formatting)
    lib/voidbox.sh              # Shared void-box helpers (sourced by each lab)
    01_prompt_injection/        # Prompt injection via unsanitized input
    02_docker_socket_escape/    # Escape via mounted Docker socket
    03_privileged_container_escape/  # Escape via --privileged disk mount
    04_cgroup_escape/           # Escape via cgroups v1 release_agent
```

Each lab contains:
- `README.md` — step-by-step instructions and what to observe
- `exploit.sh` — self-contained, runnable exploit script (Docker + void-box)
- `expected_output.md` — reference output for comparison

## Conventions

### Shell scripts

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Scripts must be self-contained — no external dependencies beyond Docker (and
  optionally void-box).
- Scripts must clean up after themselves (remove proof files, unmount, etc.).
- Each `exploit.sh` sources `../lib/output.sh` (colors, assertions) and
  `../lib/voidbox.sh` (void-box helpers) — in that order.
- Each `exploit.sh` runs the Docker exploit first, then the void-box comparison.
  Void-box is always optional — if not installed, expected behavior is shown.
- Output follows a consistent format:
  - `[Host]` prefix for host baseline info
  - `[*]` for informational steps
  - `[!]` for exploit results / evidence
  - `[Docker]` / `[Void-Box]` for environment-specific output
  - Section headers use `━━━` separator bars
  - Summary tables use box-drawing characters
- Show environment info (hostname, kernel) to make isolation boundaries visible.

### Lab design principles

- **Deterministic**: Labs use shell scripts, not real LLMs, for reproducibility.
  Prompt injection (lab 01) simulates the agent's behavior because LLM outputs
  are non-deterministic — the security proof is the same either way.
- **Evidence-based**: Each exploit shows concrete proof (host files read, host
  processes listed, different kernels visible) rather than just pass/fail labels.
- **Side-by-side comparison**: Each lab runs the exploit in Docker, then shows
  the same attempt in void-box to make the isolation difference visible.
- **Graceful degradation**: Scripts handle platform differences (macOS vs Linux,
  cgroups v1 vs v2) and explain what would happen on the target platform. When
  void-box is not available, expected behavior is shown inline.
- **Correct exploit category**: Model the actual attack mechanism accurately.
  For example, prompt injection is natural-language hijacking of the LLM, not
  shell injection via `eval`. Reference real-world incidents when possible
  (e.g., Clinejection for prompt injection).
- **Assertion-based verification**: Every claim about what the exploit can or
  cannot do must be backed by a `pass`/`fail`/`warn` check. Narrative output
  alone is not enough — assertions make the lab trustworthy and regression-safe.
  Docker assertions verify the exploit *succeeds* (e.g., secrets >= 4). Void-box
  assertions verify the exploit is *contained* (e.g., secrets = 0).
- **Honest reporting**: Report what actually happens, even when inconvenient.
  If busybox bundles `wget` in the void-box initramfs, report it as `[WARN]`
  with context — don't hide it. Honesty builds trust in the lab's conclusions.
- **Single probe, both environments**: When checking environment properties
  (secrets, network, tools), use a single probe script run identically in Docker
  and void-box. Never duplicate check logic between environments — the difference
  in results should come from the environment, not from different code.
  Lab-specific probes go in the lab folder (e.g., `01_prompt_injection/probe.sh`).
  Probes shared across labs go in `lib/`.
- **Dynamic summary tables**: Build summary values from actual observed data,
  not hardcoded strings. When void-box didn't run, label values as "(expected)"
  to distinguish them from live results.

### Output helpers

Each lab sources `labs/lib/output.sh` which provides:
- Terminal colors (`C_RED`, `C_GREEN`, etc.) — auto-disabled when piped
- Semantic functions: `header`, `title`, `dim`, `danger`, `safe`, `label`
- Assertion functions: `pass`, `fail`, `warn`
- Result functions: `result_bad`, `result_good`
- Utility: `parse_val <text> <key>` for structured key=value parsing

Always use the semantic functions instead of inline escape codes. Write
`pass "secrets_in_env=0"` not `echo -e "${C_GREEN}[PASS]${C_RESET} ..."`.
Raw `C_*` vars are acceptable only inside `printf` format strings (e.g.,
summary table cells) where a function call doesn't fit.

### Void-box integration

Each lab sources `labs/lib/voidbox.sh` (after `output.sh`) which provides:
- `VOIDBOX_AVAILABLE` — boolean indicating if voidbox is available
- `voidbox_status` — prints availability status (call once at lab start)
- `run_in_voidbox <name> <cmd>` — runs a command in a micro-VM
- `voidbox_ok <result>` / `voidbox_output <result>` — parse results

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

Run all labs:

```bash
./run_all.sh
```

Or run individually:

```bash
cd labs/01_prompt_injection && ./exploit.sh
cd labs/02_docker_socket_escape && ./exploit.sh
cd labs/03_privileged_container_escape && ./exploit.sh
cd labs/04_cgroup_escape && ./exploit.sh
```

All labs require Docker. Void-box is optional — each lab shows expected void-box
behavior if the binary is not available.

Lab 04 (cgroup escape) requires cgroups v1 + `CAP_SYS_ADMIN` for the full
exploit — on cgroups v2 (Docker Desktop, modern Linux) it explains why the
exploit fails.

## Related projects

- [void-box](https://github.com/the-void-ia/void-box) — Micro-VM agent runtime
- [void-control](https://github.com/the-void-ia/void-control) — Control plane for void-box
