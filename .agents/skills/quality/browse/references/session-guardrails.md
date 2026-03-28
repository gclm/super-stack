# Session Guardrails

Use this reference when `browse` needs host selection, fallback order, or session lifecycle rules.

## Host Guidance

- Claude Code: prefer `super-stack-browser` when available
- Codex: prefer `super-stack-browser` when available

Stable browser entrypoints:

- `~/.super-stack/runtime/bin/super-stack-browser`
- `~/.super-stack/runtime/bin/super-stack-browser-health`
- `~/.super-stack/runtime/bin/super-stack-browser-reset`

If browser tooling is unavailable, say so clearly and fall back to screenshots, local preview inspection, logs, test output, or code reasoning with explicit limits.

## Fallback Order

When original-page browser evidence cannot be obtained, use this order:

1. user-provided screenshots or pasted page text
2. trusted mirrors or reposts
3. raw HTML or static fetch extraction
4. search snippets or third-party summaries

Always say explicitly when a fallback source was used.

## Lifecycle Rules

- default to one stable session for serial work
- do not improvise alternative browser stacks when `super-stack-browser` is available
- do not let concurrent independent tasks share one live session unless the host workflow truly requires it
- use `super-stack-browser-health` as the first stop for leaked process or memory suspicion
- use `super-stack-browser-reset` as the supported cleanup path instead of ad hoc manual killing
- for `content-publish`, draft fill and final publish are different actions; final publish requires explicit confirmation
