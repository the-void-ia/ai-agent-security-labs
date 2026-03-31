# Lab 05: Void-Box Comparison

## Overview

Repeats the escape techniques from labs 02-04 inside a [void-box](https://github.com/the-void-ia/void-box) micro-VM and shows that none of them work. The key difference: each agent runs in its own KVM-backed micro-VM with its own kernel, so there is no shared kernel to exploit.

## What You'll Learn

- The Docker socket doesn't exist inside a micro-VM
- Host block devices are not visible from the guest
- Guest cgroups operate within the guest kernel, not the host's
- Hardware virtualization (VT-x/AMD-V) provides a fundamentally different isolation boundary

## Prerequisites

- [void-box](https://github.com/the-void-ia/void-box) installed
- Linux host with `/dev/kvm` (or macOS with Apple Silicon for Virtualization.framework)
- Docker (for the comparison runs)

## How It Works

The script runs two environments side by side:

1. **Docker container** — runs each escape technique (same as labs 02-04)
2. **Void-box micro-VM** — attempts the same techniques and shows they fail

For each technique, the script shows:
- What happens in Docker (escape succeeds)
- What happens in void-box (escape fails)
- Why the difference exists

## Run

```bash
./exploit.sh
```

## What to Observe

| Escape Technique | Docker | Void-Box |
|-----------------|--------|----------|
| Docker socket access | Host control | Socket doesn't exist |
| Privileged disk mount | Host filesystem | No host devices visible |
| Cgroup release_agent | Host code execution | Guest kernel only |

## Architecture Difference

```
Docker Container:                    Void-Box Micro-VM:
┌─────────────┐                     ┌─────────────────┐
│  Container   │                     │  Guest VM        │
│  (process)   │                     │  (own kernel)    │
├─────────────┤                     ├─────────────────┤
│  Shared      │ ← escape here      │  Guest Kernel    │ ← isolated
│  Host Kernel │                     ├─────────────────┤
└─────────────┘                     │  VMM (KVM/VZ)    │
                                    ├─────────────────┤
                                    │  Host Kernel     │ ← not reachable
                                    └─────────────────┘
```

In Docker, an exploit in the container reaches the host kernel directly. In void-box, an exploit in the VM reaches the guest kernel — the host kernel is behind the hardware virtualization boundary.

## Void-Box Security Features Beyond Isolation

- **Seccomp-BPF**: Syscall filtering even within the guest
- **Command allowlists**: Only declared commands can execute
- **Resource limits**: CPU and memory caps enforced by the VMM
- **SLIRP networking**: User-mode networking without host network access
- **vsock communication**: Point-to-point host-guest channel, no network stack
- **Declared capabilities**: Skills not mounted in the VM don't exist at runtime
