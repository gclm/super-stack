(() => {
  const clean = (value) => (value || "").replace(/[ \t]+/g, " ").trim();
  const uniq = (items) => [...new Set(items.filter(Boolean))];
  const MAX_BODY_CHARS = 8000;

  const pickParagraphs = (root, selector) => {
    const paragraphs = [];
    for (const node of Array.from((root || document).querySelectorAll(selector))) {
      const text = (node.innerText || "")
        .split("\n")
        .map((line) => clean(line))
        .filter(Boolean)
        .join("\n")
        .trim();
      if (!text || text.length < 8) continue;
      const duplicate = paragraphs.some(
        (existing) =>
          existing === text ||
          (text.length > 40 && existing.includes(text)) ||
          (existing.length > 40 && text.includes(existing))
      );
      if (duplicate) continue;
      paragraphs.push(text);
    }
    return paragraphs;
  };

  const buildSummary = (paragraphs) => {
    const summary = [];
    let total = 0;
    for (const paragraph of paragraphs) {
      if (total >= 180) break;
      summary.push(paragraph);
      total += paragraph.length;
      if (summary.length >= 2) break;
    }
    return summary.join("\n\n").slice(0, 220).trim();
  };

  const buildBody = (paragraphs) => {
    const selected = [];
    let total = 0;
    for (const paragraph of paragraphs) {
      const next = total ? total + 2 + paragraph.length : total + paragraph.length;
      if (next > MAX_BODY_CHARS) break;
      selected.push(paragraph);
      total = next;
    }
    return selected.join("\n\n");
  };

  const textOf = (selector) => clean(document.querySelector(selector)?.innerText);

  const titleCandidates = [
    textOf("h1"),
    textOf('[data-e2e="video-desc"]'),
    textOf(".title"),
    clean(document.querySelector('meta[property="og:title"]')?.content),
    clean(document.title).replace(/\s*-\s*抖音\s*$/, ""),
  ].filter(Boolean);
  const title = titleCandidates[0] || "";

  const authorCandidates = [
    textOf('[data-e2e="video-author-name"]'),
    textOf(".author-name"),
    textOf('a[href*="/user/"]'),
    clean(document.querySelector('meta[name="author"]')?.content),
  ].filter(Boolean);
  const author = authorCandidates[0] || "";

  const publishedAt =
    textOf("time") ||
    clean(document.querySelector('meta[property="article:published_time"]')?.content);

  const summary =
    textOf('[data-e2e="video-desc"]') ||
    clean(document.querySelector('meta[name="description"]')?.content) ||
    clean(document.querySelector('meta[property="og:description"]')?.content);

  const contentRoot =
    document.querySelector("main") ||
    document.querySelector("article") ||
    document.body;

  const bodyParagraphs = pickParagraphs(contentRoot, "h1, h2, h3, p, li, div");

  const body = buildBody(bodyParagraphs);
  const stableSummary = summary || buildSummary(bodyParagraphs);

  const imageUrls = uniq(
    Array.from(document.querySelectorAll("img"))
      .map((img) => img.currentSrc || img.src || "")
      .filter((src) => /^https?:\/\//.test(src))
  ).slice(0, 30);

  return JSON.stringify(
    {
      schemaVersion: "1.1",
      adapter: "douyin-content",
      kind: "social-content",
      sourcePlatform: "douyin",
      title,
      author,
      publishedAt,
      summary: stableSummary,
      body,
      commentTotal: "",
      comments: [],
      imageUrls,
      notes: [
        "douyin-content extractor: prefers visible title/description and broad content-root text capture",
        "douyin-content extractor: broad content text is capped and deduplicated because page structure is highly dynamic",
      ],
    },
    null,
    2
  );
})()
