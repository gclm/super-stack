---
name: api-design
description: Design or review API contracts for clarity, compatibility, validation, and caller ergonomics before implementation locks in the interface.
---

# API Design

Use this skill when creating or revising an API surface such as REST endpoints, RPC handlers, webhook payloads, or SDK-facing request/response contracts.

## Read First

- current routes, handlers, or client usage
- request and response examples
- validation and auth expectations
- `.planning/REQUIREMENTS.md` and `.planning/STATE.md` if they exist

## Goals

- make the contract intuitive for callers
- keep response and error semantics consistent
- surface compatibility risks before implementation spreads
- align validation, auth, and docs with the real API shape

## Steps

1. Define the caller goal in one sentence.
2. Choose the surface shape:
   - endpoint or operation
   - method
   - request body or params
   - response shape
   - error model
3. Check naming, pagination, filtering, and mutation semantics.
4. Check backward compatibility and client impact.
5. Verify that validation and auth rules are explicit rather than implied.
6. Recommend the cleanest contract with trade-offs.

## Output

Report:

- caller goal
- proposed contract
- validation and error semantics
- compatibility notes
- caller impact
- recommendation
