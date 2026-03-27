(() => {
  const clean = (value) => (value || "").replace(/[ \t]+/g, " ").trim();
  const uniq = (items) => [...new Set(items.filter(Boolean))];
  const MAX_BODY_CHARS = 12000;

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
      if (total >= 220) break;
      summary.push(paragraph);
      total += paragraph.length;
      if (summary.length >= 3) break;
    }
    return summary.join("\n\n").slice(0, 240).trim();
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
  const contentRoot =
    document.querySelector(".article-viewer") ||
    document.querySelector(".markdown-body") ||
    document.querySelector("article");

  const title =
    textOf(".article-title") ||
    textOf("h1") ||
    clean(document.querySelector('meta[property="og:title"]')?.content) ||
    clean(document.title).replace(/\s*-\s*掘金\s*$/, "");

  const author =
    textOf(".author-info-box .author-name") ||
    textOf(".byline-box .username") ||
    clean(document.querySelector('meta[name="author"]')?.content);

  const publishedAt =
    textOf(".meta-box time") ||
    textOf(".meta-box") ||
    clean(document.querySelector('meta[property="article:published_time"]')?.content);

  const bodyParagraphs = pickParagraphs(
    contentRoot || document,
    "p, li, blockquote, h2, h3, h4, h5, pre"
  );

  const summary =
    clean(document.querySelector('meta[name="description"]')?.content) ||
    clean(document.querySelector('meta[property="og:description"]')?.content) ||
    buildSummary(bodyParagraphs);

  const body = buildBody(bodyParagraphs);

  const imageUrls = uniq(
    Array.from((contentRoot || document).querySelectorAll("img"))
      .map((img) => img.currentSrc || img.src || "")
      .filter((src) => /^https?:\/\//.test(src))
  ).slice(0, 30);

  return JSON.stringify(
    {
      schemaVersion: "1.1",
      adapter: "juejin-article",
      kind: "article",
      sourcePlatform: "juejin",
      title,
      author,
      publishedAt,
      summary,
      body,
      commentTotal: "",
      comments: [],
      imageUrls,
      notes: [
        "juejin-article extractor: title/author/body extracted from article-viewer or markdown-body",
        "juejin-article extractor: paragraph dedupe enabled to reduce markdown-body nesting noise",
      ],
    },
    null,
    2
  );
})()
