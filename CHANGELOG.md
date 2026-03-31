# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial lab structure with 5 security labs
- Lab 01: Prompt injection simulation (deterministic, no LLM required)
- Lab 02: Docker socket escape — sibling container reads host files, writes to host `/tmp`
- Lab 03: Privileged container escape — mount host block devices from `--privileged` container
- Lab 04: Cgroup v1 release_agent escape — arbitrary code execution on host (graceful fallback on cgroups v2)
- Lab 05: Docker vs void-box comparison — runs same checks in both environments side by side
- `AGENTS.md` with project conventions for AI coding agents
- `CLAUDE.md` with Claude Code specific guidance

[Unreleased]: https://github.com/the-void-ia/ai-agent-security-labs/commits/main
