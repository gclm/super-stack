(() => {
  const clean = (value) => (value || "").replace(/[ \t]+/g, " ").trim();
  const uniq = (items) => [...new Set(items.filter(Boolean))];
  const MAX_BODY_CHARS = 12000;

  const pickParagraphs = (root, selector) => {
    const seen = new Set();
    const paragraphs = [];

    for (const node of Array.from((root || document).querySelectorAll(selector))) {
      const raw = (node.innerText || "")
        .split("\n")
        .map((line) => clean(line))
        .filter(Boolean)
        .join("\n");
      const text = raw.trim();
      if (!text || text.length < 8) continue;

      const duplicate = paragraphs.some(
        (existing) =>
          existing === text ||
          (text.length > 40 && existing.includes(text)) ||
          (existing.length > 40 && text.includes(existing))
      );
      if (duplicate || seen.has(text)) continue;
      seen.add(text);
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
    document.querySelector("#js_content") ||
    document.querySelector(".rich_media_content") ||
    document.querySelector("article");

  const title =
    textOf("#activity-name") ||
    textOf(".rich_media_title") ||
    clean(document.title);

  const author =
    textOf("#js_name") ||
    textOf(".profile_nickname") ||
    clean(document.querySelector('meta[name="author"]')?.content);

  const publishedAt =
    textOf("#publish_time") ||
    clean(document.querySelector("#meta_content .rich_media_meta_text")?.innerText);

  const bodyParagraphs = pickParagraphs(
    contentRoot || document,
    "p, li, blockquote, h2, h3, h4, pre"
  );

  const summary =
    clean(document.querySelector('meta[property="og:description"]')?.content) ||
    clean(document.querySelector('meta[name="description"]')?.content) ||
    buildSummary(bodyParagraphs);

  const body = buildBody(bodyParagraphs);

  const imageUrls = uniq(
    Array.from((contentRoot || document).querySelectorAll("img"))
      .map((img) => img.dataset.src || img.currentSrc || img.src || "")
      .filter((src) => /^https?:\/\//.test(src))
  ).slice(0, 30);

  return JSON.stringify(
    {
      schemaVersion: "1.1",
      adapter: "wechat-article",
      kind: "article",
      sourcePlatform: "wechat",
      title,
      author,
      publishedAt,
      summary,
      body,
      commentTotal: "",
      comments: [],
      imageUrls,
      notes: [
        "wechat-article extractor: title/author/time/body extracted from WeChat article DOM",
        "wechat-article extractor: body paragraphs deduplicated and capped for cleaner content acquisition output",
      ],
    },
    null,
    2
  );
})()
