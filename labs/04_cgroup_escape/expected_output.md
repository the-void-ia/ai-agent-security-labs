# Expected Output: Lab 04 - Cgroup Escape

## On cgroups v2 (Docker Desktop, modern Linux)

```
=== Lab 04: Cgroup Escape (release_agent) ===

[*] This exploit uses cgroups v1 release_agent to execute
    commands on the HOST from inside a container.

[*] Launching container with CAP_SYS_ADMIN and AppArmor disabled...

[*] Inside the container. Collecting environment info...

    hostname=b8f01233c5e1
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
```

## On Linux with cgroups v1

```
=== Lab 04: Cgroup Escape (release_agent) ===

[*] This exploit uses cgroups v1 release_agent to execute
    commands on the HOST from inside a container.

[*] Launching container with CAP_SYS_ADMIN and AppArmor disabled...

[*] Inside the container. Collecting environment info...

    hostname=a1b2c3d4e5f6
    kernel=5.4.0-150-generic

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
    root         2  0.0  0.0      0     0 ?        S    Jan01   0:00 [kthreadd]
    ...

    [!] The process list above shows HOST processes, not container processes.
    [!] hostname and kernel confirm this ran outside the container.
```

## Key Observation

On cgroups v1, the exploit achieves **arbitrary code execution as root on the host**. The proof:
- `hostname` and `kernel` in the output match the **host**, not the container
- Process list shows host services (init, kthreadd, systemd), not container processes
- The script ran outside all container namespaces

On cgroups v2, the exploit fails at step 1 — this is a real mitigation, but many production environments still run cgroups v1.
