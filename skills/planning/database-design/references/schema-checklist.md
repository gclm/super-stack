# Schema Checklist

Use this reference when `database-design` is active and you need a stronger schema review path.

## Core Questions

- what are the main entities?
- what identifies each record?
- what relationships are required?
- what queries must be fast?
- what invariants must the database enforce?

## Constraint Areas

- primary keys
- uniqueness
- foreign keys
- nullability
- soft-delete behavior
- retention and audit needs

## Indexing Questions

- what are the dominant filters?
- what joins are frequent?
- what sort order matters?
- what index cost is acceptable on writes?

## Evolution Questions

- will old and new shapes coexist?
- is a backfill required?
- can the schema change be additive first?
- what rollback path exists?
