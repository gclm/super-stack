---
name: database-design
description: Design or review database schemas, indexes, constraints, and data access trade-offs before implementation hardens around weak persistence choices.
---

# Database Design

Use this skill when a task changes persistence structure, query shape, indexing, or long-term data modeling.

## Read First

- current schema, models, or migration files
- query patterns and access paths
- data integrity or retention constraints
- `.planning/REQUIREMENTS.md` and `.planning/STATE.md` if they exist

## Goals

- choose a schema that matches actual query and mutation paths
- make constraints and invariants explicit
- surface index, migration, and compatibility implications early
- avoid accidental coupling between application convenience and poor data design

## Steps

1. Restate the entities, relationships, and lifecycle rules.
2. Identify the dominant read and write paths.
3. Design the schema and constraints around those paths.
4. Check indexing, uniqueness, foreign key, and soft-delete implications.
5. Consider migration and backfill cost if the data already exists.
6. Report trade-offs rather than pretending there is only one valid shape.

## Output

Report:

- entities and relationships
- recommended schema shape
- indexes and constraints
- migration implications
- trade-offs and risks
