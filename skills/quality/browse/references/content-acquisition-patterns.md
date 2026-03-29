# Content Acquisition Patterns

Use this reference when `browse` is being used as a browser-driven content acquisition foundation rather than only a frontend debugging tool.

## Purpose

This reference standardizes how `browse` should extract article or post content from browser-visible pages.

It is meant to support:

- WeChat article acquisition
- Xiaohongshu note acquisition
- Douyin content acquisition
- Juejin article acquisition
- future browser-driven publishing workflows that need a stable read-first baseline

## Current Mode Boundary

At this stage, `browse` supports three conceptual modes:

1. `content-read`
2. `content-publish`
3. `frontend-debug`

Only `content-read` is considered implemented as a stable default flow here.

`content-publish` is intentionally kept behind stronger confirmation boundaries because it has external side effects.

## Shared Content Schema

Content extraction should prefer a stable schema with these fields:

- `schemaVersion`
- `adapter`
- `kind`
- `sourcePlatform`
- `title`
- `author`
- `publishedAt`
- `summary`
- `body`
- `commentTotal`
- `comments`
- `imageUrls`
- `notes`

The goal is to make later reporting, retrospective analysis, and future publish flows consume the same shape.

## Platform Patterns

### WeChat Article

Priority:

1. `#js_content`
2. `.rich_media_content`
3. article-level fallback

Minimum evidence:

- landed URL
- title
- author
- publish time
- rendered body text

### Xiaohongshu Note

Priority:

1. note title
2. note body
3. visible comments
4. gallery image URLs

Minimum evidence:

- landed URL
- title
- author
- body
- comment summary when visible

### Douyin Content

Priority:

1. visible description or title
2. visible author
3. broad visible content-root text

Minimum evidence:

- landed URL
- title or description
- author if visible
- rendered page text snapshot

### Juejin Article

Priority:

1. `.article-viewer`
2. `.markdown-body`
3. `article`

Minimum evidence:

- landed URL
- title
- author
- publish time when visible
- body text

## Fallback Rules

When the platform-specific root is unavailable:

1. use the strongest visible content container
2. fall back to `document.body.innerText` only when no better content root is available
3. record that fallback in `notes`

Do not silently present body-wide extraction as if it came from a platform-specific content root.

## Future Publish Boundary

The purpose of `content-read` is not only to fetch content now, but also to serve as the read-side foundation for future browser-driven publishing skills.

Future `content-publish` flows should reuse:

- platform recognition
- stable browser tooling
- structured extraction for preview validation
- explicit pre-publish confirmation

Before `content-publish` is introduced as a default capability, these rules should hold:

- draft fill may be automated
- preview is required
- final publish click requires explicit confirmation

## Original-Page First Rule

When the user gives a concrete URL and asks for page or article analysis, treat original-page browser evidence as the default path, not a best-effort enhancement.

Apply this order:

1. confirm browser tooling is actually available
2. open the original page in browser tooling
3. capture title, landed URL, author, publish time, and the strongest rendered content root
4. only if original-page evidence is blocked, state the blocker explicitly and then use a fallback source

Do not do this silently:

- start with `curl`, `requests`, mirror pages, or search summaries while browser tooling is available
- quote mirror or raw HTML content as if it came from the original page
- omit the fact that the original page was verification-gated or login-gated

## Misuse Example

Weak path:

- user gives a WeChat article URL
- agent tries `curl` or `requests` first
- raw HTML or mirror content becomes the main evidence
- browser is only used after the user corrects the route

Preferred path:

- user gives a WeChat article URL
- agent routes to `browse`
- browser preflight runs when appropriate
- the original page is opened first and the rendered article container is extracted
- if the page is blocked by verification, the report says so explicitly before falling back
