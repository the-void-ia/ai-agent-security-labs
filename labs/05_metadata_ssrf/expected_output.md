# Lab 05: Expected Output

## Docker (simulated cloud reachability): Cloud Metadata SSRF

```
[Docker] Inside the agent container (simulated cloud reachability — no --privileged, no caps):
    hostname=<container-id>
    kernel=<host-kernel>

[*] Step 1: Agent discovers the metadata service...
[*] Step 2: Querying metadata service...
    /latest/meta-data/ → ami-id instance-id iam/
    instance-id: i-0abc123def456789a

[!] Step 3: Stealing IAM credentials...
    IAM role discovered: agent-production-role
    Credentials:
    {
      "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
      "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
      ...
    }

[!] Step 4: Reading user-data (often contains bootstrap secrets)...
    export DB_PASSWORD="super-secret-db-password-2026"
    export DEPLOY_KEY="ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

### Docker (default) Assertions

```
    [PASS] metadata_reachable=YES (metadata endpoint accessible)
    [PASS] iam_creds_stolen=YES (IAM credentials retrieved: AKIAIOSFODNN7EXAMPLE)
    [PASS] instance_id=i-0abc123def456789a (instance identity exposed)
    [PASS] userdata_accessible=YES (bootstrap secrets exposed)

[Docker] RESULT: IAM credentials stolen via simulated metadata SSRF. (4/4 assertions passed)
```

## Docker (network-isolated): Same SSRF Attempt

```
    [PASS] metadata_reachable=NO (network isolation blocks metadata)
    [PASS] iam_creds_stolen=NO (no credentials accessible)

[Docker mitigated] RESULT: Network isolation blocks metadata access.
```

## Void-Box: Same SSRF Attempt (blocked by default)

```
    [PASS] metadata_reachable=NO (SLIRP blocks link-local by default)
    [PASS] iam_creds_stolen=NO (no credentials to steal)
    [PASS] kernel=<vm-kernel> (different from host: <host-kernel>)

[Void-Box] RESULT: Metadata unreachable by default. No opt-in mitigation needed.
```

## Summary Table

```
┌─────────────────────┬───────────────────┬───────────────────┬───────────────────┐
│                     │ Docker (cloud)    │ Docker (isolated) │ Void-Box          │
├─────────────────────┼───────────────────┼───────────────────┼───────────────────┤
│ Metadata reachable? │ YES               │ NO                │ NO                │
│ IAM creds stolen?   │ YES               │ NO                │ NO                │
│ Mitigation needed?  │ YES (vulnerable)  │ explicit opt-in   │ none (default)    │
├─────────────────────┼───────────────────┼───────────────────┼───────────────────┤
│ Blast radius        │ HIGH              │ CONTAINED         │ CONTAINED         │
└─────────────────────┴───────────────────┴───────────────────┴───────────────────┘
```
