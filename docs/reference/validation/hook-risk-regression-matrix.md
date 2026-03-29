# Hook Risk Regression Matrix

Records the readonly hook allow / ask verdicts for stability checks.

## Strategy

Two tiers only (no deny):

- `allow`: whitelisted read-only commands auto-approved
- `ask`: everything else falls through to host default confirmation

See docs/architecture/decisions/readonly-command-hook.md for full design.

## Basic Info

- Verification date:
- Host:
- Hook script version:
- super-stack version or commit:

## Scenario Matrix

| ID | Command | Expected | Risk | Evidence | Result | Notes |
|----|---------|----------|------|----------|--------|-------|
| H1 | `pwd` | allow | low | | | |
| H2 | `git status` | allow | low | | | |
| H3 | `pwd && rg TODO README.md` | allow | low | | | |
| H4 | `sed -n '1,100p' file.txt` | allow | low | | | |
| H5 | `sed -n ... && printf '\n---\n' && sed -n ...` | allow | low | | | |
| H6 | `cat file.txt 2>/dev/null` | allow | low | | | |
| H7 | `rg --files docs | sort` | allow | low | | | |
| H8 | `nl -ba file.txt | sed -n '1,120p'` | allow | low | | | |
| H9 | `printf 'hello'` | allow | low | | | |
| H10 | `git branch -d old-branch` | ask | medium | | | |
| H11 | `git branch -D old-branch` | ask | medium | | | |
| H12 | `echo hi > out.txt` | ask | medium | | | |
| H13 | `mkdir tmp-build` | ask | medium | | | |
| H14 | `git add README.md` | ask | medium | | | |
| H15 | `rm -rf tmp-build` | ask | medium | | | |
| H16 | `git reset --hard` | ask | medium | | | |
| H17 | `git clean -fdx` | ask | medium | | | |
| H18 | `dd if=/dev/zero of=test.img bs=1M` | ask | medium | | | |
| H19 | `shutdown -h now` | ask | medium | | | |
| H20 | `open https://example.com` | ask | medium | | | |
| H21 | `curl https://example.com` | ask | medium | | | |
| H22 | `for f in *.txt; do echo "$f"; done` | ask | medium | | | |

## Evidence Checklist

- hook output JSON
- `harness/.runtime/super-stack-readonly-hook.log`
- host correctly executes allow
- ask correctly falls through to host default

## Conclusion

- Overall result:
- Risk drift found:
- Rules to add:
