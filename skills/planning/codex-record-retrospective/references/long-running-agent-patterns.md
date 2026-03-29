# Long-Running Agent Patterns

Use this reference when a retrospective involves long tasks, multi-session execution, repeated stop/resume cycles, or signs that the agent stopped before the work was truly complete.

This reference distills lessons from:

- the WeChat article about extracting skills from OpenAI Harness Engineering
- the open-source `stellarlinkco/skills` repository, especially its `harness` skill and hook design

## Why This Matters

Some retrospective failures are not ordinary routing mistakes.
They happen because the task actually needed a long-running execution model, but the workflow treated it like a normal one-shot turn.

In those cases, the real issue may be:

- no persistent progress artifact
- no structured task decomposition
- no explicit completion criteria
- no recovery rule after interruption
- no reflection gate before final stop

## Signals To Look For

Treat these as high-value retrospective signals:

- the assistant declared completion early, but review or verify later found obvious unfinished work
- the user had to repeatedly restate "continue", "you haven't finished", or "check the original request again"
- the task spanned multiple sessions, but there was no durable progress artifact beyond chat memory
- an interrupted session resumed with weak or incorrect state reconstruction
- the same subproblem was re-opened because earlier checkpoints were not recorded clearly
- a large task had many implicit subtasks but no structured dependency list or completion checklist
- a task was "done" because code existed, not because objective validation passed

## Reusable Lessons

Common lesson ids worth considering:

- `premature_completion`
- `missing_progress_artifacts`
- `weak_completion_criteria`
- `resume_recovery_gap`
- `missing_reflection_gate`

If the evidence is weak or one-off, keep the lesson provisional.

## What To Borrow From Harness-Like Systems

These patterns are the most reusable for super-stack:

### 1. Progress Artifacts As Recovery Context

Long tasks should not rely only on chat memory.
A durable artifact such as a task ledger, progress file, or state JSON makes recovery and retrospective analysis much stronger.

For super-stack, this suggests:

- preserve retrospective artifacts and evolution ledger entries
- when a task is likely to span sessions, prefer writing structured state rather than only narrating progress in chat

### 2. Explicit Completion Criteria

A task is not complete because the assistant feels done.
A task is complete when its objective validation path has passed.

For super-stack, this suggests:

- keep strengthening `verify`
- treat "implemented" and "validated" as different states
- when planning larger work, make acceptance and validation paths explicit early

### 3. Recovery Rules Matter

Long-running systems work because stop/resume behavior is defined.
Without recovery rules, interruptions produce duplicate work, missed work, or false completion claims.

For super-stack, this suggests:

- retrospective should call out whether the session recovered correctly after interruption
- automation should favor artifact output that helps the next run resume with evidence

### 4. Reflection Before Final Stop

The `harness` design uses a reflection gate to ask whether the original request is truly complete.
This is valuable even without copying hook behavior directly.

For super-stack, this suggests:

- daily retrospective automation should compare delivered work against the original request shape
- `ship` and `verify` can benefit from a final completeness pass for complex tasks

## What Not To Copy Directly

Do not import harness behavior wholesale into super-stack without careful design review.
In particular, these are not safe defaults for the shared workflow runtime:

- blocking stop hooks by default
- unconditional infinite-loop execution semantics
- destructive rollback behaviors such as automatic `git reset --hard`
- assuming every task should be turned into a structured task ledger

super-stack should borrow the patterns, not blindly inherit the runtime behavior.

## Where Lessons Usually Belong

When these signals repeat, they often map to:

- `verify` skill or `protocols/verify.md`
- `ship` skill
- `plan` skill or planning templates
- retrospective references and recommendation mapping
- automation prompts for daily review flows

## Review Questions

When a retrospective smells like a long-running execution issue, ask:

- Was the task actually too large for a one-shot workflow?
- Was there a missing progress artifact that would have prevented rework?
- Did the agent stop because it was truly done, or because it lost certainty?
- Would a reflection gate or stronger verify wording have caught the miss?
- Is this a reusable workflow lesson or just one unusually messy project?
