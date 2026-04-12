# Expected Output: Lab 03 - Privileged Container Escape

> Terminal output includes color highlighting (bold headers, red/green/yellow for
> PASS/FAIL/WARN, colored summary table). Colors are auto-disabled when piped.

## On Docker Desktop (macOS/Windows)

The exploit escapes into the Docker Desktop LinuxKit VM. The data partition contains Docker's internal state (all container data, volumes, etc.).

```
=== Lab 03: Privileged Container Escape ===

[Host]   hostname=your-hostname  kernel=6.x.x-...
[*] void-box not found — void-box sections will show expected behavior.
    ...

[*] Launching a privileged container...
[*] This simulates an agent container started with --privileged
    to 'simplify permissions' or 'access GPU/devices'.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Docker: Privileged Container Escape
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Docker] Inside the privileged container:
    hostname=abc123def456
    kernel=6.10.14-linuxkit

[*] Step 1: Block devices visible from inside the container:
    Disk /dev/vda: 1024 GB, ...
    Disk /dev/vdb: 550 MB, ...

    These are the HOST disks, not the container's. The container
    should not be able to see physical block devices.

[*] Step 2: Mounting /dev/vda1 read-only (proof without modifying host)...
    mount: SUCCESS — host disk now readable at /mnt/host

[*] Step 3: Reading data from the mounted host disk:

    [host disk] Docker data directory:
    buildkit
    containers
    ...

    [host disk] machine-id: 1a92e0029a8c4bacb6ec6507dbb028cd

[!] Root directory listing of host disk:
    cni
    containerd
    docker
    ...

[Docker] Environment probe results:
    block_devices_visible=YES  count=3
    mountable_partition=/dev/vda1
    can_mount_host_disk=YES
    can_read_hostname=NO  host_hostname=none
    can_read_shadow=NO
    can_read_docker_data=YES  containers=3
    probe_hostname=abc123def456  probe_kernel=6.10.14-linuxkit

[Docker] Verifying exploit results...
    [PASS] block_devices_visible=YES (3 host disks exposed)
    [PASS] can_mount_host_disk=YES (mounted /dev/vda1)
    [PASS] can_read_docker_data=YES (3 containers' data accessible)

[Docker] RESULT: Host disk mounted and concrete host data exposed via --privileged. (3/3 assertions passed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Void-Box: Same Escape Attempt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[*] The agent tries the same escape — but there are no host devices in the VM.
[*] Running the SAME probe.sh inside a void-box micro-VM...

[Void-Box] Expected (void-box not installed):
    block_devices_visible=NO  (no host disks exposed)
    can_mount_host_disk=NO    (nothing to mount)
    can_read_hostname=NO      (no host files accessible)
    can_read_shadow=NO        (no password hashes)
    can_read_docker_data=NO   (no Docker data)
    probe_kernel=<vm-kernel>  (different from host)

[Void-Box] Assertions skipped (void-box not installed).
[Void-Box] Expected: no host devices, nothing to mount, blast radius contained.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────┬──────────────────────────┬──────────────────────────┐
│                     │ Docker                   │ Void-Box                 │
├─────────────────────┼──────────────────────────┼──────────────────────────┤
│ Host devices?       │ YES (3 disks)            │ NO (expected)            │
│ Mount host disk?    │ YES (/dev/vda1)          │ NO (expected)            │
│ Read host files?    │ YES                      │ NO (expected)            │
├─────────────────────┼──────────────────────────┼──────────────────────────┤
│ Blast radius        │ HIGH                     │ NONE                     │
└─────────────────────┴──────────────────────────┴──────────────────────────┘

[*] --privileged exposes host block devices to the container.
    The container mounts the host disk and reads /etc/shadow, Docker data, SSH keys.
    Void-box has its own kernel — host devices are behind the hardware boundary.
```

## On a native Linux host

On a real Linux host, the Docker output includes more host files:

```
[*] Step 3: Reading data from the mounted host disk:

    [host disk] /etc/hostname: my-linux-host
    [container] hostname:      a1b2c3d4e5f6

    [host disk] /etc/os-release:
    NAME="Ubuntu"
    VERSION="22.04.3 LTS (Jammy Jellyfish)"
    ID=ubuntu

    [host disk] /etc/shadow (first 3 lines):
    root:$6$...:19000:0:99999:7:::
    daemon:*:19000:0:99999:7:::
    bin:*:19000:0:99999:7:::

    [host disk] SSH keys in /root/.ssh/:
    -rw-------  1 root root 2602 Jan 10 09:00 id_rsa
    -rw-r--r--  1 root root  571 Jan 10 09:00 id_rsa.pub

[Docker] Verifying exploit results...
    [PASS] block_devices_visible=YES (2 host disks exposed)
    [PASS] can_mount_host_disk=YES (mounted /dev/sda1)
    [PASS] can_read_hostname=YES (host: my-linux-host)
    [PASS] can_read_shadow=YES (password hashes accessible)
    [PASS] can_read_docker_data=YES (15 containers' data accessible)

[Docker] RESULT: Host disk mounted and concrete host data exposed via --privileged. (5/5 assertions passed)
```

## With void-box installed

```
[Void-Box] Environment probe results:
    block_devices_visible=NO
    can_mount_host_disk=NO
    can_read_hostname=NO
    can_read_shadow=NO
    can_read_docker_data=NO
    probe_hostname=void-box  probe_kernel=6.1.x

[Void-Box] Verifying isolation claims...
    [PASS] block_devices_visible=NO (no host disks exposed)
    [PASS] can_mount_host_disk=NO (nothing to mount)
    [PASS] can_read_hostname=NO (no host files accessible)
    [PASS] can_read_shadow=NO (no password hashes accessible)
    [PASS] kernel=6.1.x (different from host: 25.3.0)

[Void-Box] RESULT: No host devices. Nothing to mount, nothing to read. Blast radius contained.
```

## Key Observations

1. **Host kernel matches container kernel**: Both show `6.10.14-linuxkit` — proving the container shares the host's kernel (unlike a micro-VM which has its own).

2. **Block devices exposed**: `--privileged` makes physical disks (`/dev/vda`, `/dev/sda`) visible to the container. These belong to the host, not the container.

3. **Docker data = all containers**: On Docker Desktop, the mounted disk contains Docker's data directory — `containers`, `volumes` — meaning one privileged container can read every other container's filesystem and data.

4. **Platform-adaptive assertions**: On Docker Desktop, the probe finds Docker data but may not find `/etc/hostname` or `/etc/shadow` on the mounted partition. On native Linux, more host files are often accessible. The lab only declares success when it finds at least one concrete host artifact after the mount.

5. **Read-only demo, same boundary failure**: The lab mounts read-only to avoid modifying the host during a demo. The isolation break is already proven once the container can mount a host partition and read host-only data.

6. **Same probe, both environments**: The identical `probe.sh` runs in Docker (where `--privileged` enables the escape) and void-box (where no host devices exist). The hardware boundary makes the difference.
