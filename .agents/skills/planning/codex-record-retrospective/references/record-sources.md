# Record Sources

Use this reference when a retrospective depends on Codex local records rather than only the target repository.

## Typical Codex Record Sources

Check the strongest available sources first:

- `scripts/find_codex_project_records.py`
  - repository-managed path scan for project-specific retrospective work
- `scripts/extract_codex_session_timeline.py`
  - repository-managed session timeline extractor for turning raw JSONL traces into readable user / assistant / tool chronology
- `~/.codex/history.jsonl`
  - broad message-level history
- `~/.codex/session_index.jsonl`
  - session lookup metadata
- `~/.codex/sessions/`
  - active or indexed session storage when available
- `~/.codex/archived_sessions/`
  - archived JSONL session traces
- `~/.codex/logs_1.sqlite`
  - runtime-level evidence if text history is insufficient

## Matching Strategy

Prefer narrowing by:

- exact project path
- `cwd`
- nearby timestamps
- session ids appearing in both index and history
- explicit mentions of repository name, module name, or task terms

Do not start with a global dump unless path-based filtering clearly fails.
Do not assume the current live session is already indexed into these sources.

## Evidence Boundaries

Be explicit about what each source can and cannot prove:

- `scripts/find_codex_project_records.py`
  - best default entry for a concrete project path
  - tries to correlate `session_index`、`sessions`、`archived_sessions`、`history.jsonl`
  - reports evidence gaps when exact path correlation is missing
- `scripts/extract_codex_session_timeline.py`
  - best second step after candidate session ids are known
  - extracts user messages, assistant messages, tool calls, tool outputs, and key events into a readable timeline
  - reduces manual second-pass reading, but still does not replace human judgment about route quality or semantic drift
- `history.jsonl`
  - good for prompts, replies, and repeated problem wording
  - weaker for exact file mutations
  - may not contain the current live session yet
- `session_index.jsonl` / `sessions/`
  - good for session grouping and path correlation
  - may be incomplete if sessions were archived or interrupted
  - may lag behind the active live conversation
- `archived_sessions/`
  - good for older completed runs
  - may require timestamp correlation
- sqlite logs
  - stronger for runtime evidence
  - higher effort; use when text traces are insufficient

## Retrospective Questions

Look for patterns such as:

- Was the initial route wrong
- Did scope drift midstream
- Did Codex skip `plan`, `debug`, `review`, `verify`, or `qa` when it should not have
- Did verification happen too late or too weakly
- Did the conversation require repeated user corrections
- Did host limits get mistaken for project problems
- Did multi-agent stay unused because of rule weakness or because delegation truly was not justified

## What To Feed Back

Only feed back lessons that are reusable:

- recurring route misses
- repeated wording that confuses stage choice
- repeated environment misunderstandings
- repeated verification overclaims
- repeated design or artifact-type drift

Do not feed back:

- one-off project messiness
- missing business requirements specific to a single project
- isolated user preference that already exists in shared conventions
