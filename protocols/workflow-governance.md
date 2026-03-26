# Workflow Governance

Use this protocol when workflow defaults matter more than task-specific implementation detail.

## State Continuity

When work changes direction midstream, update `STATE.md` explicitly instead of leaving the new direction only in conversation context.
Version `.planning/` by default when it is being used as shared project memory.
Ignore only machine-local or host-generated artifacts under `.planning/`, not the planning records themselves.

Recommended state fields when scope or architecture is evolving:

- `last scope change`
- `last architecture change`
- `verification status`
- `temporary unblock decisions`

## Documentation And Commit Defaults

Use these defaults unless the target project explicitly overrides them:

- user-facing communication should default to Chinese, including assistant replies, plan summaries, verification notes, and script prompt text
- user-reviewable docs should default to Chinese
- docs that need user confirmation should be written in Chinese first
- user-facing script output, warnings, prompts, and validation summaries should default to Chinese unless an external tool requires English
- code, config keys, commands, paths, and protocol identifiers should remain in English
- if a repository needs bilingual docs, prefer Chinese body text with preserved English technical terms

When making commits for a project that adopts super-stack defaults, use Angular commit structure with Chinese summaries:

- format: `type(scope): 中文摘要`
- examples:
  - `feat(runtime): 增加本地运行态探测`
  - `docs(plan): 补充阶段决策记录`
  - `refactor(frontend): 拆分运行时页面结构`

## Shared Operating Guards

## Transient Network Defaults

When downloads, dependency installs, or remote fetches fail and the error looks transient rather than deterministic, do not stop at the first failure.

Treat these as likely transient failures first:

- SSL handshake failures
- certificate errors that appear intermittently under VPN or proxy routing
- connection reset, timeout, broken pipe, or similar transport interruptions
- temporary CDN or mirror fetch failures

Default handling:

1. First check whether the command itself is correct.
2. If the command looks correct and the failure looks network-related, retry instead of immediately concluding the dependency is unavailable.
3. Wait a random short backoff before retrying, such as 3-12 seconds for early retries.
4. Retry at least 3 times before escalating unless the failure is clearly deterministic, such as 404, permission denied, or invalid package names.
5. If mirrors are configurable, try an alternate official or trusted mirror after repeated transient failures.
6. After repeated failures, report both the command and the transient symptoms so the user can decide whether to switch VPN, proxy, or network conditions.

Do not classify a dependency as permanently unavailable after a single flaky network failure.

- If the user changes product entry shape, current-phase scope, architecture direction, database strategy, or reference-reuse boundary, explicitly backtrack to `plan` before more implementation.
- Distinguish missing tools from shell initialization failures before concluding an environment cannot support verification.
- Run the smallest real build/check path early on new scaffolds or unstable environments instead of delaying all validation until after broad implementation.
- For design or prototype tasks, identify the artifact type before producing UI output; do not default to a marketing homepage when the real target is an existing product flow.
- For fork-based product redesign, define upstream-merge boundaries before broad UI rewrites so design exploration does not hide long-term maintenance risk.
- Distinguish `review`, `verify`, and `qa` explicitly:
  - `review` finds risks in an existing change
  - `verify` proves whether the requested result is complete
  - `qa` validates real user flows or runtime behavior
- If the user asks for one of the quality stages above, do not stay in `build` by inertia.
- Distinguish “multi-agent configured” from “multi-agent should be used now”:
  - configuration only enables the capability
  - actual delegation still depends on host/session policy, explicit escalation, and clean task decomposition
  - do not force multi-agent on tightly coupled critical-path work just because the feature exists

## Reference Reuse Default

When a user asks to "use" or "reference" an existing project frontend, do not assume that means copying the implementation verbatim.

Default interpretation:

- reuse information architecture
- reuse interaction structure
- reuse page hierarchy and module boundaries
- avoid copying low-quality single-file or tightly coupled implementations directly

Only inherit implementation details directly when the user clearly asks for code-level reuse or when the reference code quality is already compatible with the current project goals.
