# Layered Entry Strategy

Use this reference when a repository is unfamiliar and you need enough understanding to work safely without turning the scan into an unbounded full-repo archaeology dig.

## Principle

Enter an unfamiliar project in layers:

1. baseline layer
2. design layer
3. target layer

Do not jump straight to deep target implementation details before the baseline is stable.
Do not stay in baseline exploration after the target boundary is already clear.

## Layer 1: Baseline

Goal:

- establish the project's real runtime shape
- confirm where code, tests, docs, scripts, and deployment entrypoints live
- identify the minimum stack and module boundaries needed to avoid wrong assumptions

Typical evidence:

- `README*`
- top-level manifests
- `AGENTS.md`
- `docs/*`
- `harness/*`
- build config
- directory tree
- CI / scripts / env config

Questions:

- what kind of system is this
- where is the active application code
- what are the main modules and execution entrypoints
- how is it built, tested, and run

Stop condition:

- you can name the active module, stack, entrypoints, and main boundary lines without guessing

## Layer 2: Design

Goal:

- understand the local design around the area that the user is likely to change
- confirm the nearby architecture, contracts, persistence, integrations, and verification path

Typical evidence:

- controllers / handlers / routes
- services / use cases
- entities / schema / mappers
- related docs and API contracts
- tests near the target area

Questions:

- what design is already in place near the target
- what constraints will shape the change
- what assumptions seem implicit but important

Stop condition:

- you can explain the nearby design and list the likely change points

## Layer 3: Target

Goal:

- inspect only the code paths required by the user's explicit objective
- prepare implementation, planning, or review with bounded scope

Typical evidence:

- exact files to modify
- exact interfaces to extend
- exact tests or verification commands

Questions:

- what exactly must change
- what should not be changed in this pass
- what verification is strong enough for this specific request

Stop condition:

- the next stage can begin without further broad exploration

## Escalation Rule

If the target layer reveals hidden architectural uncertainty, step back one layer explicitly:

- target -> design
- design -> baseline

Do not silently keep widening the scan.

## Smell Checks

You are probably exploring too broadly if:

- you are reading unrelated modules just because they exist
- you are scanning every controller or every table without a target reason
- you cannot explain why a file matters to the current request
- the user asked for one module but the scan has expanded to the whole product

You are probably exploring too narrowly if:

- you do not know how the target module is invoked
- you cannot name the persistence or integration boundary it depends on
- you cannot say how the work will be verified
