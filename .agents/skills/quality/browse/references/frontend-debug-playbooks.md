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

Recommended command pattern:

```bash
bash scripts/smoke/browser-debug-report.sh \
  --url "http://localhost:3000" \
  --selector "#app" \
  --network-filter "/api/" \
  --hint "白屏，怀疑启动异常或 bootstrap 接口失败" \
  --output artifacts/browser-debug-white-screen.md
```

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

Recommended command pattern:

```bash
bash scripts/smoke/browser-debug-report.sh \
  --url "http://localhost:3000/orders" \
  --selector ".orders-page" \
  --network-filter "/orders" \
  --hint "列表为空，怀疑 orders API 请求失败或未触发" \
  --output artifacts/browser-debug-orders-api.md
```

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

Recommended command pattern:

```bash
bash scripts/smoke/browser-debug-report.sh \
  --url "http://localhost:3000/profile" \
  --selector ".profile-form" \
  --hint "保存按钮不可点击，先看结构和状态" \
  --output artifacts/browser-debug-profile-button.md
```

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

Recommended command pattern:

```bash
bash scripts/smoke/browser-debug-report.sh \
  --url "http://localhost:3000/dashboard" \
  --selector ".dashboard-grid" \
  --hint "卡片布局错位，优先排查 grid/flex 和容器层级" \
  --output artifacts/browser-debug-dashboard-layout.md
```

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

Recommended command pattern:

```bash
bash scripts/smoke/browser-debug-report.sh \
  --url "http://localhost:3000/app" \
  --selector "#app" \
  --network-filter "/auth" \
  --hint "登录后仍跳转，怀疑 session 刷新或鉴权守卫循环" \
  --output artifacts/browser-debug-auth-loop.md
```

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
