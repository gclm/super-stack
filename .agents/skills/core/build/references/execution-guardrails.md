# Execution Guardrails

Use this reference when `build` risks drifting because requirements changed mid-implementation or because temporary unblock work could be mistaken for finished design.

## 1. Backtrack Triggers

Explicitly backtrack instead of coding forward when:

- product entry shape changed
- current-phase scope changed
- architecture direction changed
- database strategy changed
- reference-reuse boundary changed
- the request became ambiguous while coding

Typical routes:

- `build -> plan`
- `build -> discuss`
- `build -> debug`
- `build -> tdd-execution`
- `build -> review`
- `build -> verify`
- `build -> qa`

Route to `debug` when:

- the reported issue is a bug
- a test is failing but the cause is unknown
- behavior is flaky
- output is wrong and the failure path is not yet confirmed

Route to `tdd-execution` when:

- the task changes observable behavior
- the task fixes a reproducible bug
- a practical automated test path exists
- RED can be made meaningful without excessive harness work

Route to `review` when:

- the user asked for audit, risk scan, PR review, or merge readiness
- the code already exists and the main need is findings rather than implementation
- the work should be judged for regressions, security, or missing tests before more coding

Route to `verify` when:

- implementation already exists
- the main question is "is it actually done"
- fresh evidence is needed to map the current result to the requested outcome

Route to `qa` when:

- the task depends on user-flow confidence, smoke validation, or runtime behavior
- staging, preview, browser, or host-side interaction matters more than diff inspection
- the user is asking for end-to-end confidence rather than a code-centric audit

## 2. State Writeback

Update `.planning/STATE.md` when any of these change:

- active phase
- current focus
- blockers
- verification status
- temporary-vs-final decisions

## 3. Temporary Unblock Classification

When adding a placeholder asset, stub provider, temporary config, or scaffold unblock patch, classify it as one of:

- `temporary unblock`
- `scaffold default`
- `approved final choice`

Do not let unblock work silently become product truth.
