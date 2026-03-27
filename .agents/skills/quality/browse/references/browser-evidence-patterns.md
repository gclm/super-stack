# Browser Evidence Patterns

Use this reference when `browse` is active and you need more concrete browser-side evidence patterns.

## Pick Evidence By Question

- layout problem
  - inspect DOM structure
  - inspect computed styles
  - inspect viewport or responsive state
- behavior problem
  - reproduce the interaction
  - capture before/after DOM state
  - check disabled/hidden/loading states
- runtime failure
  - inspect console errors and warnings
  - inspect failed network requests
  - inspect response payload or status code
- visual regression
  - compare screenshot evidence
  - check typography, spacing, overflow, and clipping

## Frontend Debug Sequence

When the browser task is really frontend analysis or bug triage, prefer this order:

1. reproduce the exact user-visible symptom
2. capture the minimal DOM state that proves the symptom
3. inspect computed styles for the affected node
4. inspect console warnings and errors
5. inspect failed or suspicious network requests
6. capture a screenshot only after the structural evidence is clear

Use this sequence to avoid jumping straight to screenshots before understanding whether the bug is structural, behavioral, or data-driven.

## Scoped Investigation

When you already know the suspicious area:

- use a selector-scoped snapshot to reduce structure noise
- prefer a narrow container like `#app`, `.modal`, `.sidebar`, `.form-section`, or a stable component root
- if the selector scope is too narrow and hides the failing state, rerun once with a slightly wider parent container

When you suspect network-driven failure:

- use a URL filter for request capture, such as `/api/`, `/graphql`, `/auth/`, or a known asset path
- do not dump the full request log first if the page is busy and the relevant endpoint is already known
- if the filtered log is empty, report that explicitly and retry with a wider filter before concluding the request never fired

Recommended command pattern:

```bash
bash scripts/smoke/browser-debug-report.sh \
  --url "http://localhost:3000" \
  --selector "#app" \
  --network-filter "/api/" \
  --hint "首页白屏，怀疑接口或 hydration 异常" \
  --output artifacts/browser-debug-homepage.md
```

## Evidence Priorities

Prefer the narrowest evidence set that can prove or disprove the claim:

1. visible behavior
2. DOM state
3. console
4. network
5. screenshot

## Reporting Tips

- distinguish “observed” from “inferred”
- mention exact page, action, and result
- say when browser tooling was unavailable
- do not claim a browser fix is verified from code inspection alone
- when debugging frontend issues, say whether the strongest signal came from DOM, styles, console, or network
