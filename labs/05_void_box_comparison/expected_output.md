# Expected Output: Lab 05 - Void-Box Comparison

```
=== Lab 05: Docker vs Void-Box Comparison ===

[!] void-box (voidbox) is not installed.
    Install: curl -fsSL https://raw.githubusercontent.com/the-void-ia/void-box/main/scripts/install.sh | sh

[*] Running Docker-only comparisons. Void-box results shown as expected behavior.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test 1: Docker Socket Access
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Docker] Checking if Docker socket is accessible...
[Docker] VULNERABLE: Docker socket is accessible from the container.
[Docker] The container can create sibling containers with host access.

[Void-Box] In a void-box micro-VM:
  - /var/run/docker.sock does NOT exist
  - The guest has its own kernel — no Docker daemon runs inside
  - Even if Docker were installed in the VM, it would be isolated from the host

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test 2: Host Device Visibility (Privileged)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Docker] Listing block devices from privileged container...
[Docker] VULNERABLE: Host block devices visible:
    Disk /dev/sda: 50 GiB, ...
    Disk /dev/vda: 64 GiB, ...

[Void-Box] In a void-box micro-VM:
  - Only virtual devices (virtio) are visible
  - Host block devices (/dev/sda, /dev/nvme*) do NOT exist in the guest
  - Even with all privileges, there's nothing to mount
  - The guest kernel is separate from the host kernel

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test 3: Cgroup Release Agent
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Docker] On Linux with cgroups v1 + CAP_SYS_ADMIN:
  - Container can set release_agent to execute commands on host
  - Commands run as root on the host, outside the container
  - See Lab 04 for full demonstration

[Void-Box] In a void-box micro-VM:
  - Guest cgroups operate within the guest kernel
  - release_agent executes inside the VM, not on the host
  - The host kernel's cgroup hierarchy is not accessible
  - Even a full guest kernel compromise is contained by KVM/VZ

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────┬──────────────────┬──────────────────┐
│ Escape Technique    │ Docker           │ Void-Box         │
├─────────────────────┼──────────────────┼──────────────────┤
│ Docker socket       │ HOST CONTROL     │ Not applicable   │
│ Privileged mount    │ HOST FILESYSTEM  │ Not applicable   │
│ Cgroup release      │ HOST CODE EXEC   │ Guest-only       │
├─────────────────────┼──────────────────┼──────────────────┤
│ Isolation boundary  │ Shared kernel    │ Hardware (KVM)   │
│ Escape attack       │ ~300 syscalls    │ VMM interface    │
│ surface             │                  │ (orders of mag.  │
│                     │                  │  smaller)        │
└─────────────────────┴──────────────────┴──────────────────┘

[*] The fundamental difference: containers share a kernel with the host.
    Micro-VMs have their own kernel, isolated by hardware virtualization.

[*] void-box adds further restrictions:
    - Seccomp-BPF syscall filtering
    - Command allowlists
    - Declared capabilities (skills)
    - Resource limits enforced by VMM
    - SLIRP networking (no host network access)
```

## Key Observation

Every escape technique that works against Docker fails against void-box because the fundamental isolation boundary is different:

- **Docker**: Process-level isolation via namespaces + shared kernel. Attack surface = ~300 Linux syscalls.
- **Void-Box**: Hardware-level isolation via KVM/VZ. Attack surface = VMM interface (orders of magnitude smaller).

The agent in a micro-VM has its own kernel. Even if it achieves "root" inside the VM, it's root of an isolated guest — not the host.
