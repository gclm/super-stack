---
name: integration-design
description: Design external or internal service integrations with clear contracts, failure handling, ownership boundaries, and observability before implementation spreads coupling.
---

# Integration Design

Use this skill when connecting to another service, vendor API, queue, webhook, internal platform, or cross-module boundary that can create long-lived operational coupling.

## Read First

- current integration points and adapters
- API docs, payload examples, or event contracts
- retry, timeout, auth, and idempotency expectations
- `docs/reference/requirements.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
## Goals

- make the boundary and contract explicit
- avoid leaking vendor or transport details through the codebase
- define failure handling and observability up front
- keep ownership and change impact understandable

## Steps

1. Define the integration goal and owning boundary.
2. Identify request, response, or event contracts.
3. Decide where translation should happen:
   - edge adapter
   - service layer
   - domain event mapping
4. Define timeout, retry, dedupe, and fallback behavior.
5. Check auth, secret handling, and audit implications.
6. Recommend the cleanest boundary with trade-offs.

## Output

Report:

- integration goal
- boundary ownership
- contract shape
- failure and retry policy
- observability requirements
- recommendation
