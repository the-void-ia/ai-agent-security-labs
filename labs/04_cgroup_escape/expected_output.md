# Expected Output: Lab 04 - Cgroup Escape

> Terminal output includes color highlighting (bold headers, red/green/yellow for
> PASS/FAIL/WARN, colored summary table). Colors are auto-disabled when piped.

## On cgroups v2 (Docker Desktop, modern Linux)

The exploit fails at step 1 — cgroups v2 removed the release_agent mechanism. The script explains the full attack chain for educational purposes.

```
=== Lab 04: Cgroup Escape (release_agent) ===

[Host]   hostname=your-hostname  kernel=6.x.x-...
[*] void-box not found — void-box sections will show expected behavior.
    ...

[*] This exploit uses cgroups v1 release_agent to execute
    commands on the HOST from inside a container.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Docker: Cgroup Escape
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[*] Launching container with CAP_SYS_ADMIN and AppArmor disabled...

[Docker] Inside the container:
    hostname=abc123def456
    kernel=6.10.14-linuxkit

[*] Detected cgroups: v2

[*] Step 1: Attempting to mount cgroup v1 (rdma subsystem)...
    mount: FAILED

[!] Cannot mount cgroups v1. This host uses cgroups v2.

[*] The release_agent escape requires cgroups v1 because:
    - cgroups v1 allows any subsystem to define a release_agent
    - release_agent is a path to a script executed by the HOST kernel
    - cgroups v2 removed this mechanism entirely

[*] On a Linux host with cgroups v1, the full exploit chain is:

    1. Mount cgroup v1 subsystem inside the container
    2. Enable notify_on_release on a new cgroup
    3. Set release_agent to a script path (resolved on the HOST)
    4. Write the payload script inside the container
    5. Trigger release by adding/removing a process from the cgroup
    6. The HOST kernel executes the script as root — outside the container

    The key insight: release_agent runs in the HOST kernel context,
    not inside the container. This is arbitrary code execution as root
    on the host, using a legitimate kernel feature.

[Docker] Environment probe results:
    cgroup_version=v2
    can_mount_cgroupv1=NO
    release_agent_writable=NO
    probe_hostname=abc123def456  probe_kernel=6.10.14-linuxkit

[Docker] Verifying exploit results...
    [PASS] can_mount_cgroupv1=NO (cgroups v2 — v1 mount correctly blocked)
    [PASS] release_agent_writable=NO (no v1 subsystem to write to)

[Docker] RESULT: Exploit blocked by cgroups v2 (v1 mount unavailable).
    On cgroups v1 (older Linux hosts), this exploit achieves root code execution on the host.
    The technique is well-documented and actively used in container breakouts.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Void-Box: Same Escape Attempt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[*] Even if the exploit succeeded, release_agent would execute inside
    the VM's kernel — not on the host. The hardware boundary (KVM/VZ)
    means guest kernel exploits stay in the guest.
[*] Running the SAME probe.sh inside a void-box micro-VM...

[Void-Box] Expected (void-box not installed):
    cgroup_version=v2         (guest kernel's cgroups)
    can_mount_cgroupv1=NO     (no v1 subsystem available)
    release_agent_writable=NO (no release_agent to set)
    probe_kernel=<vm-kernel>  (different from host — own kernel)

[Void-Box] Assertions skipped (void-box not installed).
[Void-Box] Expected: own kernel, release_agent targets guest only, host unreachable.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────┬──────────────────────────┬──────────────────────────┐
│                     │ Docker                   │ Void-Box                 │
├─────────────────────┼──────────────────────────┼──────────────────────────┤
│ Mount cgroup v1?    │ NO (v2 blocks it)        │ N/A (expected)           │
│ release_agent?      │ N/A (v2)                 │ guest kernel only        │
│ Escape to host?     │ BLOCKED (v2)             │ NO (expected)            │
├─────────────────────┼──────────────────────────┼──────────────────────────┤
│ Blast radius        │ BLOCKED (v2 only)        │ NONE                     │
└─────────────────────┴──────────────────────────┴──────────────────────────┘

[*] In Docker, release_agent runs in the HOST kernel context — code execution as root.
    In void-box, it runs in the GUEST kernel — the host is unreachable.
    cgroups v2 mitigates this in Docker, but many production systems still use v1.
```

## On Linux with cgroups v1

The Docker section shows the full exploit succeeding:

```
[*] Detected cgroups: v1

[*] Step 1: Attempting to mount cgroup v1 (rdma subsystem)...
    mount: SUCCESS
[*] Step 2: Enabling notify_on_release...
    notify_on_release: ENABLED
[*] Step 3: Finding container path on host filesystem...
    host_path=/var/lib/docker/overlay2/.../merged
[*] Step 4: Setting release_agent to execute our script on the HOST...
    release_agent=/var/lib/docker/overlay2/.../merged/cmd
[*] Step 5: Creating payload script...
    payload: /cmd (will be executed by the host)
[*] Step 6: Triggering release_agent...

[!] SUCCESS — command executed on the HOST:

    === EXECUTED ON HOST ===
    hostname: my-linux-host
    whoami: root
    id: uid=0(root) gid=0(root) groups=0(root)
    kernel: 5.4.0-150-generic

    === Host processes (top 10) ===
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    root         1  0.0  0.1 169236 11456 ?        Ss   Jan01   1:23 /sbin/init
    ...

[Docker] Verifying exploit results...
    [PASS] can_mount_cgroupv1=YES (v1 subsystem mountable)
    [PASS] release_agent_writable=YES (can set host code execution path)
    [PASS] kernel=5.4.0-150-generic (shared with host — release_agent runs on host)

[Docker] RESULT: Arbitrary code execution as root on the host via release_agent.
```

The summary table on v1 shows:

```
│ Blast radius        │ CRITICAL                 │ NONE                     │
```

## With void-box installed

```
[Void-Box] Environment probe results:
    cgroup_version=v2
    can_mount_cgroupv1=NO
    release_agent_writable=NO
    probe_hostname=void-box  probe_kernel=6.1.x

[Void-Box] Verifying isolation claims...
    [PASS] kernel=6.1.x (different from host: 25.3.0 — own kernel)
    [PASS] can_mount_cgroupv1=NO (no v1 subsystem available)
    [PASS] release_agent_writable=NO (no release_agent to set)

[Void-Box] RESULT: Own kernel. release_agent stays in guest. Host unreachable.
```

## Key Observations

1. **On cgroups v1**: The exploit achieves arbitrary code execution as root on the host. The proof: `hostname`, `kernel`, and process list match the host, not the container.

2. **On cgroups v2**: The exploit fails at step 1 — cgroups v2 is a real mitigation. But many production environments still run cgroups v1 (RHEL 7/8, older Ubuntu, etc.).

3. **Void-box**: Even if the exploit succeeded within the VM, `release_agent` would execute in the guest kernel. The host kernel is behind the hardware virtualization boundary and is unreachable. This is why the "different kernel" assertion is the key proof point.

4. **Adaptive assertions**: On v2, the Docker assertions verify the exploit is correctly *blocked*. On v1, they verify it *succeeds*. The summary table and blast radius adapt to what actually happened.

5. **Same probe, both environments**: The identical `probe.sh` checks cgroup version, mount capability, and release_agent writability in both Docker and void-box.
