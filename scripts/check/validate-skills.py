#!/usr/bin/env python3
"""校验 super-stack skills 的轻量结构约束。"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Iterable

DEFAULT_ROOT = Path(".agents/skills")
THIN_LINES_WARN = 120
THIN_WORDS_WARN = 900
SKIP_DIRS = {"__pycache__"}


def extract_frontmatter(text: str) -> str | None:
    stripped = text.lstrip("\ufeff")
    if not stripped.startswith("---"):
        return None
    end = stripped.find("\n---", 3)
    if end == -1:
        return None
    return stripped[3:end]


def parse_frontmatter_fields(frontmatter: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    lines = frontmatter.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)", line)
        if not match:
            i += 1
            continue
        key, rest = match.group(1), match.group(2).strip()
        if rest in {"|", ">", "|+", "|-", ">+", ">-"}:
            block_lines: list[str] = []
            i += 1
            while i < len(lines) and (
                lines[i].startswith("  ") or lines[i].startswith("\t") or not lines[i].strip()
            ):
                block_lines.append(lines[i])
                i += 1
            fields[key] = "\n".join(block_lines).strip()
            continue
        if rest == "":
            block_lines = []
            i += 1
            while i < len(lines) and (lines[i].startswith("  ") or lines[i].startswith("\t")):
                block_lines.append(lines[i])
                i += 1
            fields[key] = "\n".join(block_lines).strip() if block_lines else ""
            continue
        fields[key] = rest.strip("\"'")
        i += 1
    return fields


def discover_skill_dirs(base_path: Path) -> list[Path]:
    skill_dirs: list[Path] = []
    for root, dirs, files in os.walk(base_path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        if "SKILL.md" in files:
            skill_dirs.append(Path(root))
    return sorted(skill_dirs)


def extract_path_candidates(text: str) -> Iterable[str]:
    seen: set[str] = set()
    patterns = [
        r"`([^`]+)`",
        r"\[([^\]]+)\]\(([^)]+)\)",
    ]
    for pattern in patterns:
        for match in re.finditer(pattern, text):
            groups = [g for g in match.groups() if g]
            for candidate in groups:
                candidate = candidate.strip()
                if not candidate or candidate in seen:
                    continue
                if candidate.startswith(("http://", "https://", "/Users/", "file://")):
                    continue
                if any(ch.isspace() for ch in candidate):
                    continue
                if candidate in {"---", "JSON", "Markdown"}:
                    continue
                if "/" in candidate or candidate.endswith((".md", ".py", ".json", ".sh", ".toml")):
                    seen.add(candidate)
                    yield candidate


def resolve_candidate(repo_root: Path, skill_dir: Path, candidate: str) -> Path | None:
    normalized = candidate.rstrip(".,:;)")
    if not normalized:
        return None
    if normalized.startswith("references/"):
        return skill_dir / normalized
    if normalized.startswith("scripts/"):
        local_candidate = skill_dir / normalized
        if local_candidate.exists():
            return local_candidate
        return repo_root / normalized
    if normalized.startswith(("templates/", ".github/", "bin/")):
        return repo_root / normalized
    if normalized.startswith(("assets/", "hooks/", "design/", "techniques/", "reference/")):
        return skill_dir / normalized
    if normalized.startswith((".planning/", ".agents/", "protocols/", "docs/", "scripts/", "tests/", "bin/")):
        return repo_root / normalized
    if normalized == "AGENTS.md":
        return repo_root / normalized
    if normalized.endswith("SKILL.md") and not normalized.startswith("/"):
        if normalized.startswith("."):
            return repo_root / normalized
        return skill_dir / normalized
    return None


def count_body_lines(text: str) -> int:
    stripped = text.lstrip("\ufeff")
    if not stripped.startswith("---"):
        return len(text.splitlines())
    end = stripped.find("\n---", 3)
    if end == -1:
        return len(text.splitlines())
    body = stripped[end + 4 :]
    return len(body.splitlines())


def validate_skill(repo_root: Path, skill_dir: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    skill_file = skill_dir / "SKILL.md"
    rel_skill = skill_dir.relative_to(repo_root)
    text = skill_file.read_text(encoding="utf-8")

    frontmatter = extract_frontmatter(text)
    if frontmatter is None:
        return (["SKILL.md 缺少合法 frontmatter（`---` 包裹）"], warnings)

    fields = parse_frontmatter_fields(frontmatter)
    dir_name = skill_dir.name
    name = fields.get("name", "").strip()
    description = fields.get("description", "").strip()

    if not name:
        errors.append("缺少必填 frontmatter 字段：name")
    elif name != dir_name:
        errors.append(f"frontmatter name `{name}` 与目录名 `{dir_name}` 不一致")

    if not description:
        errors.append("缺少必填 frontmatter 字段：description")

    body_lines = count_body_lines(text)
    body_words = len(text.split())
    if body_lines > THIN_LINES_WARN:
        warnings.append(f"SKILL.md 正文共有 {body_lines} 行，已超过薄入口警戒线 {THIN_LINES_WARN} 行")
    if body_words > THIN_WORDS_WARN:
        warnings.append(f"SKILL.md 共有 {body_words} 个词，已超过薄入口警戒线 {THIN_WORDS_WARN} 个词")

    for candidate in extract_path_candidates(text):
        resolved = resolve_candidate(repo_root, skill_dir, candidate)
        if resolved is None:
            continue
        if not resolved.exists():
            errors.append(f"引用路径不存在：`{candidate}`（解析为 `{resolved.relative_to(repo_root)}`）")

    refs_dir = skill_dir / "references"
    if refs_dir.exists() and not refs_dir.is_dir():
        errors.append("`references` 存在但不是目录")

    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists() and not scripts_dir.is_dir():
        errors.append("`scripts` 存在但不是目录")

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description="校验 super-stack skills 的轻量结构约束")
    parser.add_argument("--path", default=str(DEFAULT_ROOT), help="技能根目录，默认 .agents/skills")
    args = parser.parse_args()

    repo_root = Path.cwd().resolve()
    skills_root = (repo_root / args.path).resolve()
    if not skills_root.exists():
        print(f"ERROR: 技能根目录不存在：{skills_root}")
        return 1

    skill_dirs = discover_skill_dirs(skills_root)
    if not skill_dirs:
        print("WARN: 未发现任何 skill 目录")
        return 0

    total_errors = 0
    total_warnings = 0
    print(f"校验 {len(skill_dirs)} 个 skill...\n")

    for skill_dir in skill_dirs:
        rel = skill_dir.relative_to(repo_root)
        errors, warnings = validate_skill(repo_root, skill_dir)
        status = "PASS"
        if errors:
            status = "FAIL"
        elif warnings:
            status = "WARN"

        print(f"[{status}] {rel}")
        for message in errors:
            print(f"  ERROR  {message}")
        for message in warnings:
            print(f"  WARN   {message}")
        total_errors += len(errors)
        total_warnings += len(warnings)

    print()
    if total_errors:
        print(f"校验失败：{total_errors} 个错误，{total_warnings} 个警告")
        return 1
    print(f"校验通过：0 个错误，{total_warnings} 个警告")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
