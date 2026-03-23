---
name: api-change-check
description: Review API-facing changes for contract drift, compatibility, validation, error semantics, and caller impact before merging or releasing.
---

# API Change Check

Use this skill when backend, SDK, or contract-facing work may change how callers interact with an API.

## Read First

- relevant handler, router, schema, or client files
- current request/response examples if available
- tests, docs, or changelog entries related to the API surface

## Goals

- detect contract drift before release
- surface compatibility and validation issues
- check whether clients, docs, and tests still match the API behavior

## Steps

1. Identify the API surface that changed:
   - endpoint
   - method
   - request body
   - response shape
   - status codes
   - validation or auth rules
2. Compare old expectations vs current implementation evidence.
3. Check whether callers or SDK code need changes.
4. Check whether tests and docs still match the behavior.
5. Report compatibility risk clearly.

## Output

Report:

- changed surface
- compatibility status
- caller impact
- docs/test drift
- release risk
