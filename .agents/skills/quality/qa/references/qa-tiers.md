# QA Tiers

Use this reference when `qa` is active and you need a clearer test-depth choice.

## Quick

Use when the change is narrow and low risk.

- run targeted tests
- inspect the changed flow only
- check the closest logs or screenshots

## Standard

Use for most feature work.

- run targeted tests
- run the nearest broader verification command
- validate the main user path
- inspect one or two meaningful edge cases

## Exhaustive

Use before risky release or after bug-heavy work.

- run broader verification
- test primary and secondary flows
- inspect failure paths
- inspect logs, browser behavior, and likely regression surfaces

## Reporting Rule

Match report detail to tier. Do not claim exhaustive confidence from a quick pass.
