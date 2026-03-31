# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For project structure, conventions, testing, and lab design principles, see @AGENTS.md.

## Claude-specific guidance

- Before modifying exploit scripts, read the current version first — scripts have careful quoting for nested `docker run` + `sh -c` contexts.
- When editing shell scripts inside `sh -c '...'` blocks, remember that single quotes cannot be nested — use `'\''` to escape or restructure with double quotes.
- After modifying any exploit script, test it locally before considering it done.
- Be terse: skip end-of-turn summaries.
