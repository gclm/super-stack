# Frontend Task Shaping

Use this reference when frontend work can drift because the requested artifact, product surface, or maintenance boundary is still fuzzy.

## 1. Identify The Artifact Type First

Before proposing layout, color, or typography, decide what the user is actually asking for:

- `marketing homepage`
  - a brand, landing, or acquisition-facing surface
- `product workbench`
  - an operational console, dashboard, or tool workspace
- `existing-app redesign`
  - a redesign of current product screens and flows
- `clickable prototype`
  - an interactive review artifact that simulates navigation and core actions
- `implementation-ready spec`
  - a design output meant to be translated directly into production work

Do not default to a marketing homepage when the user is really asking for a redesign of an existing product flow.

## 2. Map Real Pages And User Flows

When the product already exists, inspect the real surface before proposing design directions.

Capture at least:

- major pages
- major entry points
- core actions
- primary user flows
- pages or flows the user cares about most right now

For design tasks, this mapping is more important than early moodboarding.

## 3. Distinguish Brand Exploration From Product-Flow Exploration

Two frontend tasks can sound similar but require different outputs:

- brand exploration
  - homepage tone
  - visual language
  - positioning copy
  - first-impression direction
- product-flow exploration
  - workbench layout
  - page hierarchy
  - modal and panel behavior
  - end-to-end task flow

If the user wants to understand “what I see after login” or “how the whole product hangs together,” prefer product-flow exploration or a clickable prototype over static marketing concepts.

## 4. State The Deliverable Type Explicitly

Before implementation or handoff, state which of these you are producing:

- `visual mockup`
- `clickable prototype`
- `implementation-ready spec`

Also state what it is not.

Examples:

- “This is a clickable prototype for flow review, not a production implementation.”
- “This is a visual mockup for tone alignment, not yet a screen-by-screen redesign plan.”

## 5. Prefer Continuous Prototypes For Flow Review

When the user needs to judge continuity across login, workbench, settings, creation flows, or modals, prefer:

- one clickable prototype

over:

- several disconnected static screens

Disconnected screens are acceptable for narrow layout comparison, but they are weak for evaluating overall product coherence.

## 6. Fork And Upstream Boundary

When redesigning a fork that still needs upstream updates, define the maintenance boundary before broad UI change proposals.

Capture:

- `origin`
- `upstream`
- whether the fork is ahead, behind, or identical
- which directories are expected to keep tracking upstream
- which directories are intentionally local brand/UI layers

Do not let UI exploration ignore future merge cost.

## 7. Record Why The Previous Design Was Rejected

When the user rejects a design direction, record:

- what was rejected
- why it missed
- what remains useful
- what the next iteration must change

This prevents repeated drift such as:

- marketing page instead of product page
- attractive mockup instead of usable workbench
- disconnected screens instead of coherent prototype

## 8. Output Checklist

For design-heavy tasks, the summary should usually include:

- artifact type
- UI problem being solved
- real pages or user flows covered
- visual direction
- stability constraints
- whether fork/upstream boundaries affected the proposal
- verification or review path
