# Environment Preflight

Use this reference when `build` depends on tools, runtimes, or startup paths that may not be stable.

## Quick Checks

Before assuming a tool is missing, verify:

- shell initialization path
- effective `PATH`
- language runtime availability such as `node`, `python`, `cargo`
- package manager availability such as `npm`, `pnpm`, `uv`, `conda`
- desktop or service tooling such as `cargo-tauri`
- whether the project already declares a preferred runtime environment
- whether the user already has a default environment preference that should be reused before creating a temporary one

## Entry Path Checks

Treat these as part of the implementation surface:

- default binary or `default-run`
- `dev` command
- `run` command
- startup assets such as icons or config files

## Recording Rule

If preflight changes the execution path, write it into `.planning/STATE.md` instead of keeping it only in chat.
