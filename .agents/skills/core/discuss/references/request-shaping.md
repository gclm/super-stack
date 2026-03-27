# Request Shaping

Use this reference when early conversation could drift because the request sounds clear on the surface but is underspecified in workflow terms.

## 1. Hidden Assumptions

Surface assumptions early when they could materially change the path:

- target user or audience
- product vs validation intent
- current phase vs later phase expectations
- environment or host assumptions
- success signal expectations

## 2. Design And Prototype Requests

When the request involves UI, mockups, prototypes, or redesign, identify whether the target is:

- a new marketing surface
- an existing product flow
- a clickable prototype
- an implementation-directed redesign

Do not treat these as interchangeable.

## 3. Clarify Only What Matters

Ask only the minimum clarifying questions needed to avoid risky assumptions.

Good outcomes:

- scope boundary is explicit
- non-goals are named
- artifact type is clear when relevant
- next step can safely move to `plan`

## 4. Design Document Depth

When the request involves a proposal, design doc, architecture note, module design, or technical plan, identify the intended document depth before drafting when that choice will materially affect the structure or level of detail.

Typical depth modes:

- `brief`
  - meeting pre-read
  - fast review or decision alignment
  - light support, easy to scan
- `standard`
  - formal design review
  - cross-team alignment
  - enough structure and evidence to review trade-offs
- `deep`
  - implementation appendix
  - detailed handoff
  - rule-heavy or field-level explanation

Default rule:

- if the user does not clearly ask for an especially light memo or a detailed appendix, default to `standard`

Make these three points explicit when they affect the path:

- who the primary reader is
- what decision or action the document should support
- how much implementation detail the document needs to carry

Good outcomes:

- the document depth is explicit when the request is design- or proposal-oriented
- the next stage has enough context to produce a review doc, a standard design doc, or an appendix-heavy handoff without guessing
