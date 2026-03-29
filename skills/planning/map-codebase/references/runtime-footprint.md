# Runtime Footprint

Use this reference when key evidence may live outside the repository.

## Examples

- `~/.config`, `~/.openclaw`, `~/Library/Application Support`
- local logs
- launch agents or system services
- sockets, pid files, cache directories
- running processes

## Recording Rule

Separate:

- repository evidence
- host-runtime evidence

Do not blur them together. Both can be important, but they are not the same kind of proof.
