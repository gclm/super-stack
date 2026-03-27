(() => {
  const clean = (value) => (value || "").replace(/[ \t]+/g, " ").trim();
  const title =
    clean(document.querySelector("#detail-title")?.innerText) ||
    document.title.replace(/ - 小红书$/, "");
  const body = (document.querySelector("#detail-desc")?.innerText || "")
    .split("\n")
    .map((line) => clean(line))
    .filter(Boolean)
    .join("\n\n");
  const commentTotal =
    Array.from(document.querySelectorAll("*"))
      .map((el) => clean(el.innerText))
      .find((text) => /^共\s*\d+\s*条评论$/.test(text)) || "";

  const comments = [];
  for (const item of document.querySelectorAll(".parent-comment .comment-item")) {
    const text = clean(item.innerText);
    if (text) comments.push(text);
  }

  const authorSelectors = [
    'a[href*="xsec_source=pc_note"].name',
    'a[href*="xsec_source=pc_note"] .name',
    ".author-wrapper .author-name",
    ".author-container .author-name",
    ".note-user .username",
    'a[href*="/user/profile/"] span',
    'a[href*="/user/profile/"]',
  ];

  let author = "";
  for (const selector of authorSelectors) {
    const node = document.querySelector(selector);
    const value = clean(node?.innerText);
    if (value && value !== title && value !== body && value !== "我") {
      author = value;
      break;
    }
  }

  if (!author) {
    const scopedCandidates = Array.from(
      document.querySelectorAll(
        "#noteContainer a, #noteContainer span, #noteContainer div, .note-content a, .note-content span, .note-content div"
      )
    )
      .map((el) => clean(el.innerText))
      .filter(Boolean);
    author =
      scopedCandidates.find((text) => {
        if (text === title || text === body || text === commentTotal || text === "我") return false;
        if (text.startsWith("#")) return false;
        if (text.length > 40) return false;
        if (/^(发现|直播|发布|通知|我|关注|创作中心|业务合作|更多|打开看看|打开App|小红书)$/u.test(text)) return false;
        if (/^共\s*\d+\s*条评论$/u.test(text)) return false;
        return true;
      }) || "";
  }

  const imageUrls = [
    ...new Set(
      Array.from(document.querySelectorAll("img"))
        .map((img) => img.currentSrc || img.src)
        .filter(Boolean)
        .filter((src) => /sns-webpic/.test(src))
    ),
  ];

  return JSON.stringify(
    {
      schemaVersion: "1.1",
      adapter: "xiaohongshu-note",
      kind: "social-note",
      sourcePlatform: "xiaohongshu",
      title,
      author,
      publishedAt: "",
      summary: body,
      body,
      commentTotal,
      comments,
      imageUrls,
      notes: [
        "xiaohongshu-note extractor: title/body/comments/images extracted from current page DOM",
      ],
    },
    null,
    2
  );
})()
