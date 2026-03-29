#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

HOOK_SCRIPT="${REPO_ROOT}/scripts/hooks/readonly_command_guard.py"
WORKDIR="${HOME}/tmp/super-stack-readonly-hook-$(date +%s)"
WARNINGS=0

ok() {
  printf '[PASS] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

run_case() {
  local label="$1"
  local host="$2"
  local tool_name="$3"
  local command="$4"
  local expected="$5"
  local output

  output="$(printf '%s' "{\"tool_name\":\"${tool_name}\",\"tool_input\":{\"command\":\"${command}\"},\"cwd\":\"${WORKDIR}\",\"hook_event_name\":\"PreToolUse\"}" \
    | python3 "$HOOK_SCRIPT" --host "$host")"

  case "$expected" in
    allow)
      if printf '%s' "$output" | rg -q '"permissionDecision": ?"allow"'; then
        ok "${label}: allow"
      else
        warn "${label}: expected allow, got: ${output}"
      fi
      ;;
    ask)
      # ask returns empty JSON (fallback to host default)
      if [[ "$output" == "{}" ]]; then
        ok "${label}: ask (pass-through)"
      else
        warn "${label}: expected ask, got: ${output}"
      fi
      ;;
  esac
}

run_classify() {
  local label="$1"
  local command="$2"
  local expected_verdict="$3"

  local output
  output="$(python3 "$HOOK_SCRIPT" --host codex --classify "$command")"

  if printf '%s' "$output" | rg -q "\"verdict\": ?\"${expected_verdict}\""; then
    ok "${label}: ${expected_verdict}"
  else
    warn "${label}: expected ${expected_verdict}, got: ${output}"
  fi
}

ensure_dir "$WORKDIR/harness"
rm -f "$WORKDIR/harness/.runtime/super-stack-readonly-hook.log"

printf '== super-stack readonly hook smoke test ==\n'
printf 'hook script: %s\n' "$HOOK_SCRIPT"
printf 'workdir: %s\n' "$WORKDIR"
printf '\n'

# --- allow: basic read-only ---
run_classify "pwd" "pwd" "allow"
run_classify "git-status" "git status" "allow"
run_classify "rg" "rg -n TODO file.txt" "allow"
run_classify "cat" "cat file.txt" "allow"
run_classify "ls" "ls -la" "allow"
run_classify "head" "head -5 file.txt" "allow"
run_classify "tail" "tail -20 file.txt" "allow"
run_classify "wc" "wc -l file.txt" "allow"
run_classify "echo" "echo hello" "allow"
run_classify "printf" "printf '%s' hello" "allow"
run_classify "sort" "sort file.txt" "allow"
run_classify "uniq" "sort file.txt | uniq" "allow"
run_classify "nl" "nl -ba file.txt" "allow"
run_classify "jq" "jq '.name' file.json" "allow"
run_classify "diff" "diff a.txt b.txt" "allow"
run_classify "find" "find . -name '*.py'" "allow"
run_classify "stat" "stat file.txt" "allow"
run_classify "du" "du -sh ." "allow"
run_classify "hostname" "hostname" "allow"
run_classify "uname" "uname -a" "allow"
run_classify "whoami" "whoami" "allow"
run_classify "date" "date" "allow"

# --- allow: git read-only subcommands ---
run_classify "git-log" "git log --oneline -10" "allow"
run_classify "git-diff" "git diff HEAD" "allow"
run_classify "git-show" "git show HEAD" "allow"
run_classify "git-branch-list" "git branch" "allow"
run_classify "git-rev-parse" "git rev-parse HEAD" "allow"
run_classify "git-fetch" "git fetch" "allow"
run_classify "git-blame" "git blame file.txt" "allow"
run_classify "git-tag" "git tag" "allow"
run_classify "git-remote" "git remote -v" "allow"

# --- allow: pipelines of read-only commands ---
run_classify "git-status-pipe-head" "git status | head -5" "allow"
run_classify "pwd-and-rg" "pwd && rg TODO README.md" "allow"
run_classify "sed-n-pipeline" "sed -n '1,100p' file.txt && printf '\\n---\\n' && sed -n '1,100p' other.txt" "allow"
run_classify "rg-pipe-sort" "rg --files docs | sort" "allow"

# --- allow: stderr-to-null (read-only redirection) ---
run_classify "cat-2devnull" 'cat file.txt 2>/dev/null || echo NOT_FOUND' "allow"

# --- allow: sed -n (extract-only) ---
run_classify "sed-n" "sed -n '1,5p' file.txt" "allow"

# --- allow: package manager read-only ---
run_classify "npm-list" "npm list" "allow"
run_classify "brew-info" "brew info node" "allow"
run_classify "pip-list" "pip list" "allow"

# --- ask: high-risk commands (no deny, just ask) ---
run_classify "rm-rf" "rm -rf /tmp/test" "ask"
run_classify "rm-single" "rm file.txt" "ask"
run_classify "git-reset-hard" "git reset --hard HEAD" "ask"
run_classify "git-clean-fdx" "git clean -fdx" "ask"
run_classify "dd" "dd if=/dev/zero of=test.img bs=1M count=10" "ask"
run_classify "truncate" "truncate -s 0 file.txt" "ask"
run_classify "shutdown" "shutdown -h now" "ask"
run_classify "reboot" "reboot" "ask"

# --- ask: write commands ---
run_classify "git-add" "git add ." "ask"
run_classify "git-commit" "git commit -m 'test'" "ask"
run_classify "git-checkout" "git checkout -b feature" "ask"
run_classify "git-merge" "git merge main" "ask"
run_classify "mkdir" "mkdir tmp-build" "ask"
run_classify "cp" "cp a.txt b.txt" "ask"
run_classify "mv" "mv a.txt b.txt" "ask"
run_classify "chmod" "chmod +x script.sh" "ask"
run_classify "touch" "touch newfile.txt" "ask"
run_classify "sed-i" "sed -i '' 's/old/new/g' file.txt" "ask"

# --- ask: redirection to file ---
run_classify "redirect-stdout" "echo hi > out.txt" "ask"
run_classify "redirect-append" "echo hi >> out.txt" "ask"
run_classify "redirect-stderr-file" "cat file.txt 2>errors.log" "ask"

# --- ask: subshell / command substitution ---
run_classify "dollar-paren" 'echo $(cat file.txt)' "ask"
run_classify "backtick" 'echo `cat file.txt`' "ask"

# --- ask: complex / unknown ---
run_classify "for-loop" 'for f in *.txt; do echo "$f"; done' "ask"
run_classify "python3-script" "python3 script.py" "ask"
run_classify "curl" "curl https://example.com" "ask"
run_classify "open-gui" "open https://example.com" "ask"

# --- ask: git branch -d/-D (mutating flag on readonly subcommand) ---
run_classify "git-branch-d" "git branch -d old-branch" "ask"
run_classify "git-branch-D" "git branch -D old-branch" "ask"

# --- hook integration cases ---
run_case "claude-git-status" "claude" "Bash" "git status" "allow"
run_case "claude-pipeline" "claude" "Bash" "git status | head -5" "allow"
run_case "claude-redirect-write" "claude" "Bash" "git status > /tmp/out.txt" "ask"
run_case "codex-rg" "codex" "shell" "pwd && rg TODO README.md" "allow"
run_case "codex-rm" "codex" "shell" "rm -rf tmp-build" "ask"

# --- log file check ---
if [[ -f "$WORKDIR/harness/.runtime/super-stack-readonly-hook.log" ]]; then
  ok "readonly-hook-log: created"
else
  warn "readonly-hook-log: missing"
fi

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf 'Result: PASS\n'
else
  printf 'Result: WARNINGS (%d issues)\n' "$WARNINGS"
fi