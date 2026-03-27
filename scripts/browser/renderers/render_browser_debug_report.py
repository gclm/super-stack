#!/usr/bin/env python3

import json
import pathlib
import sys


def read_text(path: pathlib.Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8").strip()


def trim_block(text: str, limit: int = 6000) -> str:
    text = str(text or "").strip()
    if len(text) <= limit:
        return text
    return text[: limit - 3].rstrip() + "..."


def parse_jsonish(path: pathlib.Path):
    raw = read_text(path)
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def render_jsonish(data, fallback: str) -> str:
    if data is None:
        return fallback
    if isinstance(data, str):
        return trim_block(data)
    return trim_block(json.dumps(data, ensure_ascii=False, indent=2))


def main() -> int:
    if len(sys.argv) != 13:
        raise SystemExit(
            "usage: render_browser_debug_report.py <title.txt> <url.txt> <snapshot.txt> <console.txt> <errors.txt> <network.json> <health.txt> <session_name> <selector> <network_filter> <hint> <output.md>"
        )

    title_path = pathlib.Path(sys.argv[1])
    url_path = pathlib.Path(sys.argv[2])
    snapshot_path = pathlib.Path(sys.argv[3])
    console_path = pathlib.Path(sys.argv[4])
    errors_path = pathlib.Path(sys.argv[5])
    network_path = pathlib.Path(sys.argv[6])
    health_path = pathlib.Path(sys.argv[7])
    session_name = sys.argv[8]
    selector = sys.argv[9]
    network_filter = sys.argv[10]
    hint = sys.argv[11]
    output_path = pathlib.Path(sys.argv[12])

    title = read_text(title_path) or "未识别"
    landed_url = read_text(url_path) or "未识别"
    snapshot = trim_block(read_text(snapshot_path) or "未提取到 snapshot", limit=10000)
    console = trim_block(read_text(console_path) or "未提取到 console 输出", limit=8000)
    errors = trim_block(read_text(errors_path) or "未提取到 page errors", limit=8000)
    health = trim_block(read_text(health_path) or "未提取到浏览器健康信息", limit=4000)
    network_data = parse_jsonish(network_path)
    network = render_jsonish(network_data, "未提取到 network requests")

    strongest_signal = "DOM / Snapshot"
    if errors and errors != "未提取到 page errors":
        strongest_signal = "Page Errors"
    elif console and console not in {"未提取到 console 输出", "✓ Done"}:
        strongest_signal = "Console"
    elif isinstance(network_data, dict):
        requests = (((network_data.get("data") or {}).get("requests")) or [])
        if requests:
            strongest_signal = "Network Requests"

    suggestions = []
    if strongest_signal == "DOM / Snapshot":
        suggestions.append("继续缩小到具体节点，检查结构层级和可访问树是否符合预期。")
        suggestions.append("如果结构正常，再补样式证据或 screenshot。")
    elif strongest_signal == "Page Errors":
        suggestions.append("优先定位报错堆栈、未定义变量或未捕获异常。")
        suggestions.append("修复 JS 运行时异常后，再复查 DOM 与 network。")
    elif strongest_signal == "Console":
        suggestions.append("优先处理 console 中的 warning/error，再判断是否需要更深的网络排查。")
    else:
        suggestions.append("优先看接口失败、状态码异常或未命中的目标请求。")
        suggestions.append("如果请求成功但 UI 仍异常，再回看 DOM 和 styles。")

    lines = [
        "# 浏览器前端诊断报告",
        "",
        "## 页面信息",
        "",
        f"- 标题：{title}",
        f"- 落地链接：`{landed_url}`",
        f"- 会话：`{session_name}`",
        f"- DOM 关注范围：`{selector or '默认整页'}`",
        f"- Network 过滤：`{network_filter or '未过滤'}`",
        f"- 调试提示：{hint or '未提供'}",
        "",
        "## 调查顺序",
        "",
        "1. 复现页面并确认标题与落地链接",
        "2. 采集页面结构 snapshot",
        "3. 采集 console 输出",
        "4. 采集 page errors",
        "5. 采集 network requests",
        "6. 附带浏览器健康状态，便于判断是否存在会话污染",
        "",
        "## 调查结论模板",
        "",
        f"- 当前最强信号：`{strongest_signal}`",
        f"- 推荐下一步：{suggestions[0]}",
        *( [f"- 备选下一步：{item}" for item in suggestions[1:]] if len(suggestions) > 1 else [] ),
        "",
        "## Snapshot",
        "",
        "```text",
        snapshot,
        "```",
        "",
        "## Console",
        "",
        "```text",
        console,
        "```",
        "",
        "## Page Errors",
        "",
        "```text",
        errors,
        "```",
        "",
        "## Network Requests",
        "",
        "```json",
        network,
        "```",
        "",
        "## Browser Health",
        "",
        "```text",
        health,
        "```",
        "",
        "## 使用建议",
        "",
        "- 如果最强信号来自 `Snapshot`，优先看 DOM 结构和可访问树",
        "- 如果最强信号来自 `Console` 或 `Page Errors`，优先定位运行时异常",
        "- 如果最强信号来自 `Network Requests`，优先确认接口失败、状态码异常或资源未加载",
        "- 若浏览器健康状态异常，先重置稳定会话，再重试问题复现",
        "",
    ]

    output_path.write_text("\n".join(lines), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
