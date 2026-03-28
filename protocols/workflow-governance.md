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

Commit cadence defaults:

- prefer one commit per meaningful stage checkpoint rather than one commit after several stages have drifted together
- good checkpoint examples: `discuss` results written to `.planning/`, a stable `plan`, a bounded `build` that passes its nearest checks, or a verified refactor slice
- do not wait for the whole project to feel "done" before creating the first recoverable checkpoint on a new or unstable repository
- when the tree is still intentionally partial, the commit message should say so explicitly instead of pretending the phase is complete
- if the user is exploring a risky direction, a small checkpoint commit is preferred before the next structural step so rollback stays cheap

Reasoning:

- stage-boundary commits reduce recovery cost when direction changes
- they make review, reset, cherry-pick, and branch comparisons practical
- they prevent large pre-commit working trees from becoming the only source of truth

Commit cadence defaults:

- prefer one commit per meaningful stage checkpoint rather than one commit after several stages have drifted together
- good checkpoint examples: `discuss` results written to `.planning/`, a stable `plan`, a bounded `build` that passes its nearest checks, or a verified refactor slice
- do not wait for the whole project to feel "done" before creating the first recoverable checkpoint on a new or unstable repository
- when the tree is still intentionally partial, the commit message should say so explicitly instead of pretending the phase is complete
- if the user is exploring a risky direction, a small checkpoint commit is preferred before the next structural step so rollback stays cheap

Reasoning:

- stage-boundary commits reduce recovery cost when direction changes
- they make review, reset, cherry-pick, and branch comparisons practical
- they prevent large pre-commit working trees from becoming the only source of truth

## Shared Operating Guards

- When maintaining super-stack itself, prefer the repository path recorded in `~/.super-stack/state/source-repo-path.txt` over directory guessing.
- If the state file exists and points to a valid Git repository, use that repository as the source of truth before proposing or applying changes.
- Do not treat runtime or installed copies such as `~/.agents/skills`, `~/.codex/skills`, or `~/.super-stack/runtime` as the default source repository.
- For super-stack self-maintenance tasks, the expected order is:
  1. identify the source repository from install state
  2. confirm the path is valid
  3. only then inspect or edit skills, protocols, templates, or `AGENTS.md`

## Browser Evidence

When a task references a concrete URL and the answer depends on the page's real content, prefer browser evidence from the original page over secondary sources.

Apply these rules:

- use `super-stack-browser` first when it is available for the current host
- do not stop at `curl`, `requests`, mirror pages, or search snippets when original-page browser evidence is available
- if browser evidence cannot be obtained because of login, verification, network, or host limits, say so explicitly before using a fallback source
- do not present mirror content, raw HTML extraction, or search summaries as if they came from the original page
- treat staying on text-only fetch for concrete page analysis, while browser tooling is available, as a workflow error unless the user explicitly asked to avoid browser inspection

## Delivery Shape Alignment

When a request is design-heavy, proposal-oriented, or governance-related, do not assume the user wants direct repository edits just because the scope is concrete.

Apply these rules:

- if the expected deliverable could reasonably be either discussion-only or direct patching, make that choice explicit before `build`
- treat phrases such as "分析一下", "设计方案", "帮我评估", or "完善一下" as potentially ambiguous about edit authority when they appear together
- if the user clearly asked for implementation, say so and proceed; otherwise default to a short alignment statement that names the chosen delivery shape
- when the delivery shape changes midstream, update `STATE.md` and name the backtrack explicitly


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
- When a repository is still at scaffold, empty-directory, or pre-first-commit stage, prefer early state capture and route framing before broad implementation so later recovery does not depend on conversation memory alone.
- When a repository is still at scaffold, empty-directory, or pre-first-commit stage, try to create the first rollback-safe checkpoint as soon as planning or the first bounded slice is real, rather than leaving the entire project in one long uncommitted state.
- When a repository is still at scaffold, empty-directory, or pre-first-commit stage, try to create the first rollback-safe checkpoint as soon as planning or the first bounded slice is real, rather than leaving the entire project in one long uncommitted state.
- For design or prototype tasks, identify the artifact type before producing UI output; do not default to a marketing homepage when the real target is an existing product flow.
- For fork-based product redesign, define upstream-merge boundaries before broad UI rewrites so design exploration does not hide long-term maintenance risk.
- For `map-codebase` on clearly multi-module repositories, confirm the target module with the user before broad deep reads unless the user explicitly asked for a full-repository map.
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
