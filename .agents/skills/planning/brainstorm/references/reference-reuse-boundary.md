# Reference Reuse Boundary

Use this reference when the user wants to "use" or "reference" another project.

## Reuse Levels

### Information Architecture

- page hierarchy
- module boundaries
- conceptual grouping

### Interaction Structure

- user flows
- page transitions
- control placement

### Implementation Details

- actual code
- component structure
- CSS or styling implementation
- data-loading implementation

## Default Rule

Do not assume implementation-level reuse unless the user clearly asks for it or the reference quality is already aligned with the current goal.

For validation samples and refactor-heavy work, prefer:

- information architecture reuse
- interaction structure reuse
- implementation rebuild
