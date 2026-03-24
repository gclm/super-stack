#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

URL=""
OUTPUT=""
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"
BROWSER_BIN="${HOME}/.claude-stack/bin/super-stack-browser"

usage() {
  cat <<'EOF'
Usage:
  scripts/smoke-test-browser-extraction.sh --url URL [--output PATH]

Examples:
  scripts/smoke-test-browser-extraction.sh \
    --url "https://www.xiaohongshu.com/explore/..." \
    --output test/xiaohongshu-note.md
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      URL="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "${URL}" ]] || die "--url is required"
[[ -x "${BROWSER_BIN}" ]] || die "stable browser entry not found: ${BROWSER_BIN}. Run ./scripts/install.sh --host all --mode global first."

if [[ -z "${OUTPUT}" ]]; then
  ensure_dir "${REPO_ROOT}/test"
  OUTPUT="${REPO_ROOT}/test/browser-extraction-$(date +%Y%m%d-%H%M%S).md"
else
  case "${OUTPUT}" in
    /*) ;;
    *) OUTPUT="${REPO_ROOT}/${OUTPUT}" ;;
  esac
  ensure_dir "$(dirname "${OUTPUT}")"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

META_JSON="${TMP_DIR}/meta.json"
IMAGES_JSON="${TMP_DIR}/images.json"

cat > "${TMP_DIR}/extract_meta.js" <<'EOF'
(() => {
  const clean = (value) => (value || '').trim();
  const title = clean(document.querySelector('#detail-title')?.innerText) || document.title.replace(/ - 小红书$/, '');
  const desc = clean(document.querySelector('#detail-desc')?.innerText);
  const commentTotal = Array.from(document.querySelectorAll('*'))
    .map((el) => clean(el.innerText))
    .find((text) => /^共\s*\d+\s*条评论$/.test(text)) || '';

  const comments = [];
  for (const item of document.querySelectorAll('.parent-comment .comment-item')) {
    const text = clean(item.innerText);
    if (text) comments.push(text);
  }

  const authorSelectors = [
    'a[href*="xsec_source=pc_note"].name',
    'a[href*="xsec_source=pc_note"] .name',
    '.author-wrapper .author-name',
    '.author-container .author-name',
    '.note-user .username',
    'a[href*="/user/profile/"] span',
    'a[href*="/user/profile/"]',
  ];

  let author = '';
  for (const selector of authorSelectors) {
    const node = document.querySelector(selector);
    const value = clean(node?.innerText);
    if (value && value !== title && value !== desc && value !== '我') {
      author = value;
      break;
    }
  }

  if (!author) {
    const scopedCandidates = Array.from(
      document.querySelectorAll('#noteContainer a, #noteContainer span, #noteContainer div, .note-content a, .note-content span, .note-content div')
    )
      .map((el) => clean(el.innerText))
      .filter(Boolean);
    author = scopedCandidates.find((text) => {
      if (text === title || text === desc || text === commentTotal || text === '我') return false;
      if (text.startsWith('#')) return false;
      if (text.length > 40) return false;
      if (/^(发现|直播|发布|通知|我|关注|创作中心|业务合作|更多|打开看看|打开App|小红书)$/u.test(text)) return false;
      if (/^共\s*\d+\s*条评论$/u.test(text)) return false;
      return true;
    }) || '';
  }

  return JSON.stringify({ title, author, desc, commentTotal, comments }, null, 2);
})()
EOF

cat > "${TMP_DIR}/open_gallery.js" <<'EOF'
(() => {
  const selectors = [
    '.note-slider-box img',
    '.note-slider-img img',
    '.swiper-slide img',
    'img[src*="sns-webpic"]'
  ];

  for (const selector of selectors) {
    const candidates = Array.from(document.querySelectorAll(selector));
    for (const node of candidates) {
      const width = node.naturalWidth || node.clientWidth || 0;
      if (width >= 300) {
        node.click();
        return 'clicked';
      }
    }
  }

  return 'no-gallery-image';
})()
EOF

cat > "${TMP_DIR}/extract_images.js" <<'EOF'
(() => {
  const urls = Array.from(document.querySelectorAll('img'))
    .map((img) => img.currentSrc || img.src)
    .filter(Boolean)
    .filter((src) => /sns-webpic/.test(src));
  return JSON.stringify([...new Set(urls)], null, 2);
})()
EOF

log "opening target page with ${BROWSER_BIN}"
"${BROWSER_BIN}" open "${URL}" >/dev/null
"${BROWSER_BIN}" wait 1500 >/dev/null

LANDED_URL="$("${BROWSER_BIN}" get url)"
PAGE_TITLE="$("${BROWSER_BIN}" get title)"

"${BROWSER_BIN}" eval "$(cat "${TMP_DIR}/extract_meta.js")" > "${META_JSON}.raw"
python3 - "${META_JSON}.raw" <<'PY' > "${META_JSON}"
import json
import pathlib
import sys

raw_path = pathlib.Path(sys.argv[1])
raw = raw_path.read_text().strip()
decoded = json.loads(raw)
if not isinstance(decoded, str):
    raise SystemExit(f"expected eval output to decode to string, got {type(decoded).__name__}")
json.loads(decoded)
print(decoded)
PY

"${BROWSER_BIN}" eval "$(cat "${TMP_DIR}/open_gallery.js")" >/dev/null || true
"${BROWSER_BIN}" wait 1000 >/dev/null || true
"${BROWSER_BIN}" eval "$(cat "${TMP_DIR}/extract_images.js")" > "${IMAGES_JSON}.raw"
python3 - "${IMAGES_JSON}.raw" <<'PY' > "${IMAGES_JSON}"
import json
import pathlib
import sys

raw_path = pathlib.Path(sys.argv[1])
raw = raw_path.read_text().strip()
decoded = json.loads(raw)
if not isinstance(decoded, str):
    raise SystemExit(f"expected eval output to decode to string, got {type(decoded).__name__}")
json.loads(decoded)
print(decoded)
PY

python3 - "${META_JSON}" "${IMAGES_JSON}" "${URL}" "${LANDED_URL}" "${PAGE_TITLE}" "${OUTPUT}" <<'PY'
import json
import pathlib
import sys

meta_path, images_path, source_url, landed_url, page_title, output_path = sys.argv[1:]

meta = json.loads(pathlib.Path(meta_path).read_text())
images = json.loads(pathlib.Path(images_path).read_text())

def split_comment_block(block: str):
    lines = [line.strip() for line in block.splitlines() if line.strip()]
    if not lines:
        return None

    author = lines[0]
    body = []
    reply = []
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

comments = []
for block in meta.get("comments", []):
    parsed = split_comment_block(block)
    if parsed and parsed["body"]:
        comments.append(parsed)

lines = [
    "# 浏览器提取回归结果",
    "",
    "## 原始链接",
    "",
    f"- 输入链接：`{source_url}`",
    f"- 落地链接：`{landed_url}`",
    "",
    "## 标题",
    "",
    meta.get("title") or page_title.replace(" - 小红书", ""),
    "",
    "## 作者",
    "",
    meta.get("author") or "未识别",
    "",
    "## 图片链接",
    "",
]

if images:
    lines.extend([f"- {url}" for url in images])
else:
    lines.append("- 未提取到正文图片")

lines.extend([
    "",
    "## 博文内容",
    "",
    meta.get("desc") or "未提取到正文",
    "",
    "## 评论概览",
    "",
    f"- {meta.get('commentTotal') or '未识别评论总数'}",
    "",
    "## 该贴热门评论",
    "",
    "说明：以下为当前页面中可见的前排评论与作者回复，不包含未展开的全部楼中楼。",
    "",
])

if comments:
    for idx, item in enumerate(comments, start=1):
        lines.extend([
            f"### {idx}. {item['author']}",
            "",
            item["body"],
            "",
        ])
        if item["reply"]:
            lines.extend([
                "作者回复：",
                "",
                item["reply"],
                "",
            ])
else:
    lines.extend([
        "当前页面中未提取到可见评论。",
        "",
    ])

lines.extend([
    "## 提取说明",
    "",
    "- 浏览器入口：`super-stack-browser`",
    "- 会话：`super-stack-browser`",
    "- 元数据提取：页面 DOM",
    "- 图片提取：尝试进入正文图片区后抓取 `sns-webpic` 资源",
])

pathlib.Path(output_path).write_text("\n".join(lines) + "\n")
print(output_path)
PY

log "browser extraction report written to ${OUTPUT}"
