# Frontend Refactor Slices

Use this reference when `frontend-refactor` is active and the work needs safer slicing.

## Safe Slice Order

1. identify behavior that must remain stable
2. extract shared layout or style patterns
3. separate state flow from presentation
4. simplify routing or data-loading boundaries
5. verify core user flows after each slice

## Common Refactor Targets

- repeated layout wrappers
- duplicated form state logic
- mixed fetch/render components
- inconsistent button, modal, or table patterns
- CSS or utility sprawl

## Risks To Call Out

- hidden form behavior changes
- loading and empty-state regressions
- responsive layout breakage
- focus and keyboard interaction regressions
- stale props or derived state bugs

## Verification Hints

- inspect the most-used path first
- verify one or two edge states
- use browser evidence when behavior is UI-heavy
