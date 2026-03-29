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
- force explicit review of auth, tenant, and file or callback boundaries when the API touches them

## Steps

1. Identify the API surface that changed:
   - endpoint
   - method
   - request body
   - response shape
   - status codes
   - validation or auth rules
2. Compare old expectations vs current implementation evidence.
3. For auth, admin, tenant, workspace, callback, upload, or download APIs, review the boundary matrix:
   - who can call
   - which resource ownership boundary applies
   - which fields are writable vs server-controlled
   - which response fields may leak unnecessary data
   - which external callback or storage side effects must stay compatible
4. Check whether callers, SDK code, scripts, or fixtures need changes.
5. Check whether tests and docs still match the behavior.
6. Report compatibility risk clearly.

## Output

Report:

- changed surface
- compatibility status
- auth or ownership boundary impact
- caller impact
- docs/test drift
- release risk
