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

## 4. Incidental Issue Classification

When coding reveals adjacent problems, classify them before expanding the patch:

- `current must-fix`
  - the task would be incorrect, unsafe, or unverifiable without this fix
- `same-batch can-include`
  - tightly coupled to the touched code and low-risk to include now
- `follow-up`
  - real issue, but not required to deliver the approved task safely

Use this quick check:

- does leaving it unfixed break the requested outcome
- does it change architecture or product scope
- does it require broader validation than the current batch can support

If the answer suggests broader scope, push it to `follow-up` or backtrack to `plan`.

## 5. Boundary Matrix For High-Risk Backend Work

Before broad edits on API, auth, tenant, admin, upload, download, callback, or webhook tasks, write down:

- caller identity and allowed roles
- tenant, workspace, or resource ownership boundary
- allowed create, update, delete fields
- response fields that must be masked, omitted, or sanitized
- side effects, callbacks, or external systems touched
- strongest available verification path: `compile`, `test`, `scripted-flow`, or `real-integration`
