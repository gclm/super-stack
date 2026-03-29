#!/usr/bin/env python3
"""校验技能运行时目录与仓库 source-of-truth 的一致性。"""

from __future__ import annotations

import argparse
import hashlib
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Set, Tuple

IGNORED_NAMES = {".DS_Store"}
IGNORED_PARTS = {"__pycache__", ".git"}


@dataclass
class ParityResult:
    missing: List[str]
    mismatched: List[str]
    extra: List[str]


def iter_files(root: Path) -> Iterable[Path]:
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if path.name in IGNORED_NAMES:
            continue
        if any(part in IGNORED_PARTS for part in path.parts):
            continue
        yield path


def sha1(path: Path) -> str:
    digest = hashlib.sha1()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_skills_from_root(skills_root: Path) -> Dict[str, Tuple[Path, str]]:
    records: Dict[str, Tuple[Path, str]] = {}
    for file_path in iter_files(skills_root):
        rel = file_path.relative_to(skills_root)
        parts = rel.parts
        if len(parts) < 2:
            continue
        normalized = Path(parts[0], *parts[1:]).as_posix()
        records[normalized] = (file_path, sha1(file_path))
    return records


def merge_records(
    target: Dict[str, Tuple[Path, str]],
    incoming: Dict[str, Tuple[Path, str]],
    *,
    source_label: str,
) -> None:
    for key, value in incoming.items():
        if key in target and target[key][1] != value[1]:
            raise SystemExit(f"冲突：技能 `{key}` 在多个来源中内容不一致（来源：{source_label}）")
        target[key] = value


def collect_repo_skills(repo_root: Path) -> Dict[str, Tuple[Path, str]]:
    records: Dict[str, Tuple[Path, str]] = {}

    local_root = repo_root / "skills"
    if local_root.exists():
        local_records: Dict[str, Tuple[Path, str]] = {}
        for file_path in iter_files(local_root):
            rel = file_path.relative_to(local_root)
            parts = rel.parts
            if len(parts) < 3:
                continue
            normalized = Path(parts[1], *parts[2:]).as_posix()
            local_records[normalized] = (file_path, sha1(file_path))
        merge_records(records, local_records, source_label="skills")

    external_roots = [
        repo_root / "external-skills" / "openspace" / "openspace" / "host_skills",
        repo_root / "external-skills" / "contextweaver" / "skills",
        repo_root / "external-skills" / "obsidian-skills" / "skills",
    ]
    for external_root in external_roots:
        if not external_root.exists():
            continue
        external_records = collect_skills_from_root(external_root)
        merge_records(records, external_records, source_label=str(external_root))

    return records


def collect_runtime_skills(skills_root: Path) -> Dict[str, Tuple[Path, str]]:
    records: Dict[str, Tuple[Path, str]] = {}
    for file_path in iter_files(skills_root):
        rel = file_path.relative_to(skills_root).as_posix()
        records[rel] = (file_path, sha1(file_path))
    return records


def compare(repo_records: Dict[str, Tuple[Path, str]], runtime_records: Dict[str, Tuple[Path, str]]) -> ParityResult:
    repo_keys: Set[str] = set(repo_records)
    runtime_keys: Set[str] = set(runtime_records)

    missing = sorted(repo_keys - runtime_keys)
    extra = sorted(runtime_keys - repo_keys)

    mismatched: List[str] = []
    for key in sorted(repo_keys & runtime_keys):
        if repo_records[key][1] != runtime_records[key][1]:
            mismatched.append(key)

    return ParityResult(missing=missing, mismatched=mismatched, extra=extra)


def print_list(title: str, items: List[str], limit: int = 20) -> None:
    print(title)
    if not items:
        print("  - (none)")
        return
    for item in items[:limit]:
        print(f"  - {item}")
    if len(items) > limit:
        print(f"  - ... and {len(items) - limit} more")


def check_codex_non_system(codex_root: Path) -> List[str]:
    if not codex_root.exists():
        return []

    offenders: List[str] = []
    for entry in sorted(codex_root.iterdir()):
        if entry.name == ".system":
            continue
        offenders.append(entry.name)
    return offenders


def main() -> int:
    parser = argparse.ArgumentParser(description="校验技能运行时目录与仓库 source-of-truth 的一致性")
    parser.add_argument("--repo-root", default=".", help="仓库根目录，默认当前目录")
    parser.add_argument("--agents-skills", default=os.path.expanduser("~/.agents/skills"), help="用户 runtime 技能目录")
    parser.add_argument("--codex-skills", default=os.path.expanduser("~/.codex/skills"), help="Codex 本地技能目录")
    parser.add_argument("--strict-agents-extra", action="store_true", help="将 ~/.agents/skills 额外文件视为失败")
    parser.add_argument("--enforce-codex-system-only", action="store_true", help="要求 ~/.codex/skills 仅保留 .system")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    agents_root = Path(args.agents_skills).expanduser().resolve()
    codex_root = Path(args.codex_skills).expanduser().resolve()

    repo_records = collect_repo_skills(repo_root)
    print(f"[info] repo skill files(normalized): {len(repo_records)}")

    if not agents_root.exists():
        print(f"[warn] ~/.agents/skills 不存在，跳过 runtime parity: {agents_root}")
        agents_result = ParityResult(missing=[], mismatched=[], extra=[])
    else:
        runtime_records = collect_runtime_skills(agents_root)
        print(f"[info] runtime skill files(~/.agents/skills): {len(runtime_records)}")
        agents_result = compare(repo_records, runtime_records)

    failed = False
    if agents_root.exists():
        print_list("[check] missing in ~/.agents/skills", agents_result.missing)
        print_list("[check] content mismatches in ~/.agents/skills", agents_result.mismatched)
        print_list("[check] extra in ~/.agents/skills", agents_result.extra)

        if agents_result.missing or agents_result.mismatched:
            failed = True
        if args.strict_agents_extra and agents_result.extra:
            failed = True

    if args.enforce_codex_system_only:
        offenders = check_codex_non_system(codex_root)
        print_list("[check] non-.system entries in ~/.codex/skills", offenders)
        if offenders:
            failed = True

    if failed:
        print("[result] FAIL")
        return 1

    print("[result] PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
