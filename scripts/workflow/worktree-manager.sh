#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

GITFLOW_MAIN_BRANCH="${GITFLOW_MAIN_BRANCH:-main}"
GITFLOW_DEVELOP_BRANCH="${GITFLOW_DEVELOP_BRANCH:-develop}"
DEFAULT_WORKTREE_ROOT="${REPO_ROOT}/../_worktrees"

usage() {
  cat <<'EOF'
用法：
  scripts/workflow/worktree-manager.sh create --track <feature|release|hotfix> --name <task> [--base <branch>] [--root <dir>]
  scripts/workflow/worktree-manager.sh list
  scripts/workflow/worktree-manager.sh remove --branch <name> [--root <dir>] [--delete-branch]
  scripts/workflow/worktree-manager.sh doctor
  scripts/workflow/worktree-manager.sh help

说明（Git Flow）：
  - feature/*: 实验改动或常规开发，默认基于 develop
  - release/*: 主线维护/发布收口，默认基于 develop
  - hotfix/*: 紧急修复，默认基于 main

兼容别名：
  - exp -> feature
  - main -> release

示例：
  scripts/workflow/worktree-manager.sh create --track feature --name prompt-router
  scripts/workflow/worktree-manager.sh create --track release --name 2026-04-stabilize
  scripts/workflow/worktree-manager.sh create --track hotfix --name codex-hook-crash
  scripts/workflow/worktree-manager.sh remove --branch feature/prompt-router --delete-branch
EOF
}

ensure_git_repo() {
  git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "当前目录不是 git 仓库"
}

normalize_track() {
  case "$1" in
    feature|release|hotfix) printf '%s' "$1" ;;
    exp) printf 'feature' ;;
    main) printf 'release' ;;
    *) die "未知 track: $1（可选 feature|release|hotfix）" ;;
  esac
}

default_base_for_track() {
  case "$1" in
    feature|release) printf '%s' "${GITFLOW_DEVELOP_BRANCH}" ;;
    hotfix) printf '%s' "${GITFLOW_MAIN_BRANCH}" ;;
    *) die "未知 track: $1" ;;
  esac
}

sanitize_name() {
  local raw="$1"
  local normalized
  normalized="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr ' /' '--' | tr -cd 'a-z0-9._-')"
  [[ -n "$normalized" ]] || die "name 不能为空"
  printf '%s' "$normalized"
}

create_worktree() {
  local track=""
  local name=""
  local base_branch=""
  local root="${DEFAULT_WORKTREE_ROOT}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --track)
        track="${2:-}"
        shift 2
        ;;
      --name)
        name="${2:-}"
        shift 2
        ;;
      --base)
        base_branch="${2:-}"
        shift 2
        ;;
      --root)
        root="${2:-}"
        shift 2
        ;;
      *)
        die "create 不支持参数：$1"
        ;;
    esac
  done

  [[ -n "$track" ]] || die "create 缺少 --track"
  [[ -n "$name" ]] || die "create 缺少 --name"

  local normalized_track safe_name branch_name target_dir
  normalized_track="$(normalize_track "$track")"
  safe_name="$(sanitize_name "$name")"

  if [[ -z "$base_branch" ]]; then
    base_branch="$(default_base_for_track "$normalized_track")"
  fi

  branch_name="${normalized_track}/${safe_name}"
  target_dir="${root}/${normalized_track}-${safe_name}"

  ensure_dir "$root"

  if git -C "${REPO_ROOT}" show-ref --verify --quiet "refs/heads/${branch_name}"; then
    die "分支已存在：${branch_name}"
  fi

  if [[ -e "$target_dir" ]]; then
    die "目标目录已存在：${target_dir}"
  fi

  log "创建 worktree"
  log "  track: ${normalized_track}"
  log "  branch: ${branch_name}"
  log "  base: ${base_branch}"
  log "  path: ${target_dir}"

  git -C "${REPO_ROOT}" worktree add -b "${branch_name}" "${target_dir}" "${base_branch}"

  printf '\n下一步建议：\n'
  printf '  cd %s\n' "${target_dir}"
  printf '  git status --short\n'
}

list_worktrees() {
  git -C "${REPO_ROOT}" worktree list
}

remove_worktree() {
  local branch=""
  local root="${DEFAULT_WORKTREE_ROOT}"
  local delete_branch=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --branch)
        branch="${2:-}"
        shift 2
        ;;
      --root)
        root="${2:-}"
        shift 2
        ;;
      --delete-branch)
        delete_branch=1
        shift
        ;;
      *)
        die "remove 不支持参数：$1"
        ;;
    esac
  done

  [[ -n "$branch" ]] || die "remove 缺少 --branch"

  local worktree_path
  worktree_path="$(git -C "${REPO_ROOT}" worktree list --porcelain | awk -v b="${branch}" '
    $1=="worktree"{p=$2}
    $1=="branch" && $2=="refs/heads/" b {print p; exit}
  ')"

  if [[ -z "$worktree_path" ]]; then
    local guessed="${root}/$(printf '%s' "$branch" | tr '/' '-')"
    if [[ -d "$guessed" ]]; then
      worktree_path="$guessed"
    else
      die "未找到 branch 对应的 worktree：${branch}"
    fi
  fi

  log "移除 worktree: ${worktree_path}"
  git -C "${REPO_ROOT}" worktree remove "${worktree_path}"

  if [[ "$delete_branch" -eq 1 ]]; then
    log "删除分支: ${branch}"
    git -C "${REPO_ROOT}" branch -D "${branch}"
  fi
}

doctor() {
  printf '== worktree doctor ==\n'
  printf 'repo: %s\n' "${REPO_ROOT}"
  printf 'gitflow main branch: %s\n' "${GITFLOW_MAIN_BRANCH}"
  printf 'gitflow develop branch: %s\n' "${GITFLOW_DEVELOP_BRANCH}"
  printf 'default worktree root: %s\n' "${DEFAULT_WORKTREE_ROOT}"

  printf '\n[1] 当前工作区状态\n'
  git -C "${REPO_ROOT}" status --short

  printf '\n[2] 已注册 worktree\n'
  git -C "${REPO_ROOT}" worktree list

  printf '\n[3] 索引检查（防止误提交通道污染）\n'
  git -C "${REPO_ROOT}" diff --cached --name-only

  printf '\n提示：若 [3] 非空，请在提交前先确认 staged 是否属于当前任务。\n'
}

main() {
  ensure_git_repo

  local command="${1:-help}"
  shift || true

  case "$command" in
    create)
      create_worktree "$@"
      ;;
    list)
      list_worktrees
      ;;
    remove)
      remove_worktree "$@"
      ;;
    doctor)
      doctor
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      die "未知命令：${command}"
      ;;
  esac
}

main "$@"
