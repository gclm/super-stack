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
