# Output Shape

Use this reference when `map-codebase` needs the exact output location and file-by-file content shape.

## Output Location

Write findings under `.planning/codebase/` in the target project.

If `.planning/` does not exist, initialize it first from `templates/planning/`.

Default files:

- `STACK.md`
- `STRUCTURE.md`
- `ARCHITECTURE.md`
- `CONVENTIONS.md`
- `INTEGRATIONS.md`
- `TESTING.md`
- `CONCERNS.md`
- `SUMMARY.md`

## File Expectations

### `STACK.md`

Capture:

- languages
- frameworks
- package managers
- test tools
- deployment or runtime clues

### `STRUCTURE.md`

Capture:

- top-level directories
- where product code lives
- where tests live
- where infra or tooling lives

### `ARCHITECTURE.md`

Capture:

- major modules or services
- request or data flow
- persistence boundaries
- background jobs, workers, or queues

### `CONVENTIONS.md`

Capture:

- naming conventions
- file organization patterns
- code style habits
- branching or release conventions if visible
- documentation language and commit conventions if visible

### `INTEGRATIONS.md`

Capture:

- third-party APIs
- auth providers
- databases or caches
- webhooks, messaging, analytics, storage

### `TESTING.md`

Capture:

- test frameworks
- test directories
- common test commands
- obvious coverage gaps

### `CONCERNS.md`

Capture:

- fragile areas
- risky dependencies
- stale or confusing sections
- missing docs or verification weak spots
- documented-vs-actual mismatches in entrypoints, directory structure, or test commands

### `SUMMARY.md`

Capture:

- one-paragraph summary
- likely best entry points for future work
- questions to resolve before major changes
