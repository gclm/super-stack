# Session Guardrails

Use this reference when `browse` needs host selection, fallback order, or session lifecycle rules.

## Host Guidance

- Claude Code: prefer configured browser MCP or browser plugin when available
- Codex: prefer configured browser MCP, currently `chrome-devtools-mcp` when available

Capability probe:

- `~/.super-stack/runtime/scripts/check/check-browser-capability.sh`

If browser tooling is unavailable, say so clearly and fall back to screenshots, local preview inspection, logs, test output, or code reasoning with explicit limits.

## Fallback Order

When original-page browser evidence cannot be obtained, use this order:

1. user-provided screenshots or pasted page text
2. trusted mirrors or reposts
3. raw HTML or static fetch extraction
4. search snippets or third-party summaries

Always say explicitly when a fallback source was used.

## Lifecycle Rules

- default to one active browser tool context for serial work when the host supports it
- do not improvise repo-local wrapper stacks when the host already has a configured browser MCP or browser plugin
- do not let concurrent independent tasks share one live page/tab unless the host workflow truly requires it
- when the tool context becomes unhealthy, prefer reopening the page or restarting the host-side browser tooling cleanly
- if recovery requires a manual host action, say so explicitly instead of pretending a repo-local reset command exists
- for `content-publish`, draft fill and final publish are different actions; final publish requires explicit confirmation
