# ContextWeaver Playbook

Use this reference when `map-codebase` runs in an environment where `ContextWeaver` is installed.

## Purpose

`ContextWeaver` is an evidence retrieval accelerator:

- use it to narrow candidate files, symbols, and code paths
- do not treat retrieval output as final conclusions
- always confirm key claims by reading repository files directly

## Tool Selection Rules

Choose the smallest tool that can answer the question:

- use `read` when exact files are already known
- use `grep` when the goal is exhaustive text matches
- use `ContextWeaver` when intent is semantic and file paths are not yet clear

When `ContextWeaver` returns high-confidence targets, switch immediately to `read`.

## Preflight

Check availability:

```bash
contextweaver --version
```

If running in restricted environments where writing under home is blocked, use:

```bash
HOME=/tmp contextweaver --version
```

Index status must be ready before semantic retrieval.

## Query Style

`information-request`:

- write one concrete behavior question in natural language
- ask "how it works" and "how parts connect"
- avoid dumping many unrelated asks into one query

`technical-terms`:

- only include symbols known to exist
- avoid guessed names, raw file paths, and command literals

## Command Templates

Semantic retrieval:

```bash
contextweaver search --format json --information-request "How is map-codebase output mode selected and persisted?"
```

Prompt-context preparation for ambiguous requests:

```bash
contextweaver prompt-context --format json "Integrate ContextWeaver into map-codebase without expanding output scope"
```

When the task is broad and ambiguous, use `prompt-context` first, then use `search` with extracted terms.

## Official Skill Script Path (Recommended)

Install official skills into a local directory:

```bash
contextweaver install-skills --dir /tmp/cw-skills
```

Then call scripts directly for stable structured output:

```bash
node /tmp/cw-skills/using-contextweaver/scripts/search-context.mjs \
  --repo-path /abs/path/to/repo \
  --information-request "How does map-codebase decide minimal vs full output mode?"
```

```bash
node /tmp/cw-skills/enhancing-prompts/scripts/prepare-enhancement-context.mjs \
  --repo-path /abs/path/to/repo \
  "Integrate ContextWeaver flow into map-codebase without broadening repository scan"
```

These script paths come from the official distributed skills bundle and mirror README workflow.

## One-Question Convergence Rule

Borrowed from official prompt-enhancement flow:

- default to a recommended interpretation first
- ask at most one short question only if the answer changes implementation boundary
- after user answer, converge directly to executable task scope

Do not run repeated clarification loops for preference-only differences.

## Evidence Mapping Into `map-codebase`

Map retrieval output into these artifacts:

- `summary.md`: architectural shape and suggested entry points
- `concerns.md`: risks, ambiguities, and documented-vs-actual drift

Escalate to `full` output mode only when onboarding or audit requires broader persistent maps.
