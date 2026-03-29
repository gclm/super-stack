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

If preflight changes the execution path, write it into `harness/state.md` instead of keeping it only in chat.
- `harness/history.md` if it exists
## Transient Network Failures

If dependency installation, package downloads, or remote fetches fail and the error looks transient rather than deterministic, do not stop at the first failure.

Treat these as likely transient failures first:

- SSL handshake failures
- certificate chain errors that appear intermittently under VPN or proxy routing
- connection resets, timeouts, or broken pipe style network failures
- temporary CDN or mirror fetch failures

Retry guidance:

1. Check whether the failure is likely caused by unstable VPN, proxy, or mirror routing rather than a wrong command.
2. If the command itself looks correct, retry instead of immediately concluding the dependency is unavailable.
3. Wait a random short backoff before retrying, such as 3-12 seconds for early retries.
4. Retry at least 3 times before escalating, unless the error is clearly deterministic such as 404, permission denied, or an invalid package name.
5. If mirrors are configurable, try an alternate official or trusted mirror after repeated transient failures.
6. After repeated failures, report both the original command and the transient symptoms so the user can decide whether to switch network conditions.

Do not classify a dependency as permanently unavailable after a single flaky network failure.
