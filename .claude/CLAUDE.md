# Claude Adapter

This directory contains Claude Code-specific wiring for the shared Super Stack core.

Primary shared instructions live at the repository root in `AGENTS.md`.

## Host Notes

- Prefer root `AGENTS.md` and `.agents/skills/` as the source of truth.
- Use `.claude/hooks/` only for Claude-specific lifecycle automation.
- Do not duplicate long workflow definitions here unless the host requires it.

## Workflow

Default chain:

`discuss -> plan -> build -> review -> verify -> ship`

## Shared Assets

- root `AGENTS.md`
- `.agents/skills/`
- `templates/planning/`
- `protocols/`
