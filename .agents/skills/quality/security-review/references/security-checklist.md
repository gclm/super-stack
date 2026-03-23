# Security Review Checklist

Use this reference when `security-review` is active and you need a more detailed review path.

## Trust Boundary Questions

- who can call this path?
- what identity is trusted?
- what data crosses the boundary?
- what action becomes possible after crossing it?

## Common Review Areas

### Auth And Permissions

- missing authorization checks
- role confusion
- object-level access control gaps
- admin-only paths exposed to standard users

### Input And Execution

- unsanitized input reaching queries or shells
- path traversal or arbitrary file access
- SSRF through URL fetchers or webhooks
- unsafe deserialization or code execution

### Data Exposure

- secrets in logs or responses
- over-broad API fields
- leaking internal errors to callers
- multi-tenant data bleed

### Operational Security

- secrets in config or repo
- weak retry behavior causing abuse risk
- unaudited privileged actions
- missing rate limits on expensive or sensitive paths

## Severity Hints

- critical: easy compromise, privilege escalation, or broad data exposure
- high: realistic exploit path with meaningful impact
- medium: requires conditions or has reduced blast radius
- low: hygiene gap with limited exploitability
