---
title: OpenSpace Host Skills
---

# OpenSpace Host Skills

This group contains upstream host-facing skills imported from OpenSpace.

Current imported skills:

- `delegate-task`
- `skill-discovery`

Why this group exists:

- keep OpenSpace host skills under source-repo control
- preserve a clear boundary between upstream host skills and super-stack native skills
- continue using the existing install chain:
  - source repo stores grouped skills under `.agents/skills/<group>/<skill>/`
  - global install flattens them into `~/.agents/skills/<skill-name>/`

Sync policy:

- sync whole skill directories from upstream, not just `SKILL.md`
- treat `SKILL.md` as upstream-managed unless there is a deliberate super-stack fork decision
- record provenance and sync notes here at the group level
- when upstream changes, prefer re-import + review over ad hoc local edits

## Upstream Provenance

- upstream repo: `https://github.com/HKUDS/OpenSpace.git`
- imported from local checkout: `/Users/gclm/.super-stack/openspace`
- imported commit: `67125c378d579fe8d53a68972856d1453d80c7d9`

Current imported upstream directories:

- `openspace/host_skills/delegate-task/` -> `.agents/skills/openspace/delegate-task/`
- `openspace/host_skills/skill-discovery/` -> `.agents/skills/openspace/skill-discovery/`

Current upstream content note:

- both upstream directories currently contain only `SKILL.md`
- future syncs must still be treated as whole-directory imports so additional files are not silently dropped

Skill-specific notes:

### `delegate-task`

- upstream path: `openspace/host_skills/delegate-task/`
- current `SKILL.md` is copied verbatim from upstream

### `skill-discovery`

- upstream path: `openspace/host_skills/skill-discovery/`
- current `SKILL.md` is copied verbatim from upstream

Guardrails:

- keep trigger surfaces close to upstream unless there is an explicit super-stack fork decision
- if upstream adds more files later, re-import the whole directory instead of cherry-picking files
- keep install behavior unchanged:
  - source repo stores grouped skills
  - global install flattens to `~/.agents/skills/<skill-name>/`
