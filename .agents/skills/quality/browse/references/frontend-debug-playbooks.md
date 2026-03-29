# Frontend Debug Playbooks

Use this reference when `browse` is diagnosing frontend bugs and you want a repeatable investigation path instead of ad hoc browser poking.

Each playbook answers:

- what symptom class you are looking at
- what evidence to collect first
- what usually explains that symptom
- what to report before claiming a likely root cause

## 1. White Screen / Blank Screen

Typical symptoms:

- page appears mostly blank
- only shell chrome is visible
- content area never hydrates

Primary evidence order:

1. landed URL and title
2. selector-scoped snapshot for the app root
3. console
4. page errors
5. network requests filtered to app bootstrap or API paths

Strongest likely signals:

- `Page Errors`: runtime exception during boot
- `Console`: hydration warning, missing module, uncaught promise rejection
- `Network Requests`: app config, bundle, or bootstrap API failed
- `Snapshot`: root exists but content subtree never appears

Recommended browser-tool pattern:

- open the page in the active browser tooling
- snapshot the app root such as `#app`
- inspect console and page errors
- inspect network requests filtered to the bootstrap or API paths
- write the evidence into task artifacts or the current verification note

Report before root-cause claim:

- whether the app root exists
- whether console/page errors exist
- whether the initial data/bootstrap request fired and succeeded
- whether the issue looks structural, runtime, or data-driven

## 2. API Failure / Data Not Loading

Typical symptoms:

- list stays empty
- loading spinner never ends
- button works but data never updates
- toast or inline error appears after request

Primary evidence order:

1. reproduce the action
2. network requests filtered to the likely endpoint family
3. response status and failed request count
4. console and page errors
5. snapshot for the affected list/form container

Strongest likely signals:

- `Network Requests`: 4xx/5xx, CORS, timeout, no request fired
- `Console`: fetch wrapper error, response parsing error
- `Snapshot`: loading or error state visible but no data subtree

Recommended browser-tool pattern:

- reproduce the action
- inspect requests filtered to the likely endpoint family such as `/orders`
- capture the affected container such as `.orders-page`
- record the response status family and visible UI state

Report before root-cause claim:

- did the request fire
- if it fired, what status family returned
- if it did not fire, what user action or UI state should have triggered it
- whether UI state reflects loading, empty, or error mode

## 3. DOM Structure / Interaction State Bug

Typical symptoms:

- button not clickable
- modal missing or renders in wrong container
- element present but disabled or hidden
- content exists in code but not in visible structure

Primary evidence order:

1. reproduce the interaction
2. selector-scoped snapshot around the affected component
3. visibility/enabled/checked state when relevant
4. styles for the affected node
5. console only if structure does not explain it

Strongest likely signals:

- `Snapshot`: node absent, wrong hierarchy, wrong state
- `Styles`: hidden, covered, zero-sized, overflow-clipped
- `Console`: interaction handler threw before UI state changed

Recommended browser-tool pattern:

- capture a selector-scoped snapshot around the affected component such as `.profile-form`
- inspect visibility, enabled state, and surrounding structure
- inspect computed styles only after structure has been checked

Report before root-cause claim:

- whether the target node exists
- whether it is disabled, hidden, or clipped
- whether structure or style alone explains the issue
- whether a runtime exception is still needed to explain the symptom

## 4. Layout / Styling Regression

Typical symptoms:

- text overlaps
- card width is wrong
- modal clipped or off-screen
- mobile layout breaks at a specific viewport

Primary evidence order:

1. reproduce the visible issue
2. selector-scoped snapshot for the affected area
3. computed styles for the affected node and parent container
4. screenshot if the visual artifact matters
5. console only if style evidence is insufficient

Strongest likely signals:

- `Styles`: wrong display, width, overflow, positioning, z-index
- `Snapshot`: hierarchy mismatch causing inherited layout problems
- `Screenshot`: confirms user-visible severity after structure/style are understood

Recommended browser-tool pattern:

- capture the affected area such as `.dashboard-grid`
- inspect computed styles for the target node and parent container
- add a screenshot only after the structure/style diagnosis is clear

Report before root-cause claim:

- which node is visually wrong
- which parent container controls its layout
- whether the issue is likely caused by structure or computed style
- whether screenshot evidence adds anything beyond the structural diagnosis

## 5. Auth / Redirect Loop

Typical symptoms:

- page keeps jumping between routes
- login succeeds but protected page never stabilizes
- app lands on unauthorized state unexpectedly

Primary evidence order:

1. landed URL
2. network requests filtered to auth/session endpoints
3. console and page errors
4. snapshot for the auth gate or protected layout

Strongest likely signals:

- `Network Requests`: repeated 401/403, session refresh loops
- `Snapshot`: auth gate visible but protected content never mounts
- `Console`: token parsing or state store exceptions

Recommended browser-tool pattern:

- inspect the landed URL over time
- inspect requests filtered to auth/session endpoints such as `/auth`
- capture the auth gate or protected app root such as `#app`
- record whether protected content ever mounts

Report before root-cause claim:

- whether redirect or guard behavior is visible in landed URL changes
- whether auth endpoints loop or fail
- whether protected content ever mounts

## General Rule

Do not skip straight to the “probable fix”.

First state:

- what was reproduced
- what evidence was collected
- what the strongest signal is
- what the most likely next check is

Only then move toward a likely root cause or fix direction.
