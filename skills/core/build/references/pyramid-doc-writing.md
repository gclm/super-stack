# Pyramid Doc Writing

Use this reference when the task is to write or revise a proposal, design doc, architecture note, module design, or other user-reviewable technical document where the main risk is poor information layering rather than missing raw facts.

Default user-facing document writing should be in Chinese unless the project or external audience clearly requires another language.

## 1. Core Rule

For proposal and design documents, control layering before length.

Do not start by asking whether the document should merely be longer or shorter.
Start by asking:

- what kind of document this is
- who it is for
- what decision or action it should support
- what depth it should reach

Most document quality problems come from mixed layers, not from being slightly too long or slightly too short.

## 2. Depth Selection

Before writing, classify the document into one of three depth modes.

### `brief`

Use when the document is mainly for:

- meeting pre-read
- fast review
- decision alignment
- high-level option comparison

Target characteristics:

- conclusion first
- few sections
- light examples
- minimal implementation detail
- easy to scan quickly

### `standard`

Use when the document is mainly for:

- formal technical design review
- cross-team alignment
- module or interface design
- implementation handoff preparation without full implementation detail

This should be the default mode unless the user clearly asks for a lighter or deeper artifact.

Target characteristics:

- clear decision structure
- enough support to review trade-offs
- includes core flows, APIs, state changes, and boundaries
- avoids table-level or code-level exhaustiveness unless necessary

### `deep`

Use when the document is mainly for:

- implementation appendix
- detailed handoff
- field-level or rule-heavy explanation
- migration, rollback, or conflict-handling detail

Target characteristics:

- detailed and implementation-oriented
- not ideal as the only review document

## 3. Default Mode Rule

When the user asks for a proposal, design doc, architecture note, or module design without a stronger signal, default to `standard`.

If unsure, prefer `standard`.

## 4. Default Pyramid Structure

For `standard` proposal and design documents, use this structure as the default starting point unless the task has a stronger domain-specific required shape:

1. conclusion summary
2. why this design
3. scope and non-goals
4. core solution
5. execution surfaces such as flow, service, API, or state model
6. risks, boundaries, and next steps

In Chinese writing, this often maps well to:

1. 结论摘要
2. 为什么这样设计
3. 当前支持什么，不支持什么
4. 核心方案
5. 流程 / Service / API / 状态机
6. 风险、边界与后续

## 5. Main Document Versus Appendix

Keep decision-oriented content in the main body:

- supported scenarios
- scope and non-goals
- architecture or module shape
- core process diagrams
- service surface
- API structure
- state model
- major risks and boundaries

Move detailed execution material to appendix or implementation notes when possible:

- field-by-field DTO definitions
- table-level rules
- detailed scan rules
- conflict strategy matrices
- rollback matrices
- long pseudo code
- large test matrices
- environment-specific command sequences

When one document is clearly trying to serve all three of these goals at once, consider splitting it into separate artifacts:

- decision review
- design explanation
- implementation manual

## 6. Drift Signals

Possible signs a `standard` doc has drifted too deep:

- the main body starts listing large numbers of fields or rules
- detailed implementation notes appear in the same section as architecture or flow design
- multiple long pseudo code blocks dominate the main body
- the same process is shown as both a diagram and a long prose replay
- reviewers must read implementation detail before they can understand the main decision

Possible signs a `brief` doc is too thin:

- the conclusion exists, but the review question cannot really be answered
- core flow, service surface, or state model is missing
- scope and non-goals are still unclear

Possible signs layers are mixed:

- one section contains background, design decision, implementation detail, and rollout notes together
- the same concept is fully redefined in multiple sections
- appendix material appears before the document boundary is clear

## 7. Recovery Moves

When a draft is already too long, too thin, or mixed in layers, fix structure before trimming content.

Use this sequence:

1. identify the intended depth mode
2. label each current section by layer: decision, design, or implementation
3. move implementation-heavy sections into appendix or implementation notes
4. merge repeated concept definitions into one canonical section
5. replace repeated prose flow descriptions with one diagram plus short key points
6. only after restructuring, trim for length
