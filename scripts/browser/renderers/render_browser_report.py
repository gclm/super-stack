#!/usr/bin/env python3

import json
import pathlib
import sys


def normalize_multiline(text: str, max_chars: int | None = None) -> str:
    blocks = [block.strip() for block in str(text or "").split("\n\n")]
    lines: list[str] = []
    total = 0

    for block in blocks:
        if not block:
            continue
        normalized = "\n".join(line.strip() for line in block.splitlines() if line.strip()).strip()
        if not normalized:
            continue
        next_total = total + len(normalized) + (2 if lines else 0)
        if max_chars is not None and next_total > max_chars:
            break
        lines.append(normalized)
        total = next_total

    return "\n\n".join(lines).strip()


def split_comment_block(block: str) -> dict | None:
    lines = [line.strip() for line in block.splitlines() if line.strip()]
    if not lines:
        return None

    author = lines[0]
    body: list[str] = []
    reply: list[str] = []
    in_reply = False

    for line in lines[1:]:
      if line == "作者":
        in_reply = True
        continue
      if line in {"赞", "回复"}:
        continue
      if line.startswith("展开 "):
        continue
      if line.startswith("#"):
        continue
      if any(token in line for token in ("昨天", "今天", "分钟前", "小时前", "天前")):
        continue
      if line.count("-") == 1 and line.replace("-", "").isdigit():
        continue
      if line.isdigit():
        continue
      if len(line) <= 4 and any(ch in line for ch in "北京上海湖北荷兰新加坡四川山东江苏山西湖南"):
        continue

      if in_reply:
        reply.append(line)
      else:
        body.append(line)

    return {
        "author": author,
        "body": "\n".join(body).strip(),
        "reply": "\n".join(reply).strip(),
    }


def normalized_comments(data: dict) -> list[dict]:
    comments = data.get("comments", [])
    if not isinstance(comments, list):
        return []

    if comments and isinstance(comments[0], dict):
        return comments

    parsed: list[dict] = []
    for block in comments:
        if not isinstance(block, str):
            continue
        item = split_comment_block(block)
        if item and item["body"]:
            parsed.append(item)
    return parsed


def main() -> int:
    if len(sys.argv) != 7:
        raise SystemExit(
            "usage: render_browser_report.py <evidence.json> <source_url> <landed_url> <page_title> <session_name> <output.md>"
        )

    evidence_path, source_url, landed_url, page_title, session_name, output_path = sys.argv[1:]
    data = json.loads(pathlib.Path(evidence_path).read_text(encoding="utf-8"))
    comments = normalized_comments(data)
    images = data.get("imageUrls") or []
    notes = data.get("notes") or []
    summary = normalize_multiline(data.get("summary") or "", max_chars=300)
    body = normalize_multiline(data.get("body") or "", max_chars=12000)

    lines = [
        "# 浏览器提取回归结果",
        "",
        "## 原始链接",
        "",
        f"- 输入链接：`{source_url}`",
        f"- 落地链接：`{landed_url}`",
        "",
        "## 提取适配器",
        "",
        f"- adapter：`{data.get('adapter') or 'unknown'}`",
        f"- kind：`{data.get('kind') or 'unknown'}`",
        f"- sourcePlatform：`{data.get('sourcePlatform') or 'unknown'}`",
        "",
        "## 标题",
        "",
        data.get("title") or page_title,
        "",
        "## 作者",
        "",
        data.get("author") or "未识别",
        "",
        "## 发布时间",
        "",
        data.get("publishedAt") or "未识别",
        "",
        "## 图片链接",
        "",
    ]

    if images:
        lines.extend([f"- {url}" for url in images])
    else:
        lines.append("- 未提取到正文图片")

    lines.extend(
        [
            "",
            "## 正文摘要",
            "",
            summary or "未提取到摘要",
            "",
            "## 正文内容",
            "",
            body or "未提取到正文",
            "",
            "## 评论概览",
            "",
            f"- {data.get('commentTotal') or '未识别评论总数'}",
            "",
            "## 可见评论",
            "",
            "说明：以下为当前页面中可见的评论样本，不代表全部评论。",
            "",
        ]
    )

    if comments:
        for idx, item in enumerate(comments, start=1):
            lines.extend([f"### {idx}. {item.get('author') or '匿名'}", "", item.get("body") or "", ""])
            if item.get("reply"):
                lines.extend(["作者回复：", "", item["reply"], ""])
    else:
        lines.extend(["当前页面中未提取到可见评论。", ""])

    lines.extend(
        [
            "## 提取说明",
            "",
            "- 浏览器入口：`super-stack-browser`",
            f"- 会话：`{session_name}`",
            "- 输出格式：统一内容获取 evidence schema + Markdown renderer",
        ]
    )

    if notes:
        lines.extend(["- 提取器备注："])
        lines.extend([f"  - {note}" for note in notes if isinstance(note, str)])

    pathlib.Path(output_path).write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
