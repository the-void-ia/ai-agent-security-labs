# Lab 06: Expected Output

## Docker (broad mounts): The Common Mistake

```
[Docker] Inside the agent container (broad mounts):
    hostname=<container-id>
    kernel=<host-kernel>

[*] Agent scans for credential files...

[!] AWS credentials found!
    /root/.aws/credentials:
    [default]
    aws_access_key_id = AKIAIOSFODNN7EXAMPLE
    ...

[!] SSH private key found!
    /root/.ssh/id_ed25519 (first 4 lines):
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...

[!] Kubernetes config found!
[!] GCP credentials found!
[!] Git credentials found!

[!] The agent only needed git credentials, but it now has:
    - AWS access keys for 2 profiles (default + production)
    - SSH private key + bastion host at 10.0.1.50
    - Kubernetes production cluster token
    - GCP project credentials
    - Git credentials (the only thing it actually needed)
```

### Docker (broad) Assertions

```
    [PASS] git_credentials=YES (agent has what it needs)
    [PASS] credentials_found=5 (but agent only needed 1 — oversharing confirmed)
    [PASS] aws_credentials=YES (leaked — not needed for git push)
    [PASS] ssh_private_keys=YES (leaked — not needed for git push)
    [PASS] kube_config=YES (leaked — not needed for git push)

[Docker broad] RESULT: Agent needed 1 credential, got 5. Oversharing confirmed.
```

## Docker (targeted mount): The Careful Approach

```
    [PASS] git_credentials=YES (agent has what it needs)
    [PASS] credentials_found=1 (only git credentials — no oversharing)
    [PASS] aws_credentials=NO (not mounted)
    [PASS] ssh_private_keys=NO (not mounted)

[Docker targeted] RESULT: Only git credentials accessible. No oversharing.
```

## Void-Box: Explicit Declaration Model

```
    [PASS] credentials_found=0 (nothing declared in workflow spec)
    [PASS] aws_credentials=NO (not declared)
    [PASS] git_credentials=NO (not declared — would need explicit spec entry)
    [PASS] kernel=<vm-kernel> (different from host: <host-kernel>)

[Void-Box] RESULT: No credentials found. Declaration model prevents oversharing.
```

## Summary Table

```
┌─────────────────────┬───────────────────┬───────────────────┬───────────────────┐
│                     │ Docker (broad)    │ Docker (targeted) │ Void-Box          │
├─────────────────────┼───────────────────┼───────────────────┼───────────────────┤
│ Git credentials?    │ YES               │ YES (only this)   │ NO                │
│ AWS credentials?    │ YES (leaked)      │ NO                │ NO                │
│ Total cred types    │ 5 (overshared)    │ 1                 │ 0                 │
│ Guardrails?         │ none              │ dev discipline    │ spec is enforced  │
├─────────────────────┼───────────────────┼───────────────────┼───────────────────┤
│ Blast radius        │ HIGH              │ LOW               │ LOW               │
└─────────────────────┴───────────────────┴───────────────────┴───────────────────┘
```
