# Output Shape

Use this reference when `map-codebase` needs the exact output location and file-by-file content shape.

## Output Location

Write findings under `docs/reference/codebase/` in the target project.

If `docs/reference/codebase/` does not exist yet:

- create that directory when the repository already uses the standard `docs/ + harness/` layout
- otherwise route through `repo-bootstrap` or the repository's own documentation bootstrap path first

## Output Modes

### `minimal` (default)

Create:

- `summary.md`
- `concerns.md`

Use this mode for:

- targeted module work
- repositories that already have mature architecture docs
- post-migration projects where full map packs quickly go stale

### `full` (on demand)

Create:

- `stack.md`
- `structure.md`
- `architecture.md`
- `conventions.md`
- `integrations.md`
- `testing.md`
- `concerns.md`
- `summary.md`

Use this mode for:

- first-time onboarding to an unfamiliar repository
- explicit handoff or audit requests
- repository-level mapping where broad visibility is needed

## Escalation Rule

Start with `minimal`.

Escalate to `full` only when:

- the user explicitly asks for full repository documentation
- onboarding evidence is still insufficient after `minimal`
- verification/review stages repeatedly fail due to missing baseline map details

## File Expectations

### `stack.md`

Capture:

- languages
- frameworks
- package managers
- test tools
- deployment or runtime clues

### `structure.md`

Capture:

- top-level directories
- where product code lives
- where tests live
- where infra or tooling lives

### `architecture.md`

Capture:

- major modules or services
- request or data flow
- persistence boundaries
- background jobs, workers, or queues

### `conventions.md`

Capture:

- naming conventions
- file organization patterns
- code style habits
- branching or release conventions if visible
- documentation language and commit conventions if visible

### `integrations.md`

Capture:

- third-party APIs
- auth providers
- databases or caches
- webhooks, messaging, analytics, storage

### `testing.md`

Capture:

- test frameworks
- test directories
- common test commands
- obvious coverage gaps

### `concerns.md`

Capture:

- fragile areas
- risky dependencies
- stale or confusing sections
- missing docs or verification weak spots
- documented-vs-actual mismatches in entrypoints, directory structure, or test commands

### `summary.md`

Capture:

- one-paragraph summary
- likely best entry points for future work
- questions to resolve before major changes
