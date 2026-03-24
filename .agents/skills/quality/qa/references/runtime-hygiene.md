# Runtime Hygiene

Use this reference when QA should cover startup or toolchain quality, not just product behavior.

## Check These

- shell initialization issues
- PATH drift
- package manager warnings
- missing startup assets
- invalid default run target
- desktop app startup noise

## Reporting Rule

Treat these as real QA findings when they materially affect local development, validation, or release confidence.
