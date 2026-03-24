(() => {
  const clean = (value) => (value || "").replace(/\s+/g, " ").trim();
  const uniq = (items) => [...new Set(items.filter(Boolean))];

  const title =
    clean(document.querySelector('meta[property="og:title"]')?.content) ||
    clean(document.querySelector("title")?.innerText) ||
    clean(document.title);

  const author =
    clean(document.querySelector('meta[name="author"]')?.content) ||
    clean(document.querySelector('meta[property="article:author"]')?.content) ||
    clean(document.querySelector("article [rel='author']")?.innerText) ||
    clean(document.querySelector("article .author")?.innerText);

  const summary =
    clean(document.querySelector('meta[name="description"]')?.content) ||
    clean(document.querySelector('meta[property="og:description"]')?.content);

  const bodyCandidates = Array.from(
    document.querySelectorAll("article p, main p, article li, main li")
  )
    .map((node) => clean(node.innerText))
    .filter(Boolean)
    .filter((text) => text.length >= 20);

  const body = bodyCandidates.join("\n\n");

  const imageUrls = uniq(
    [
      clean(document.querySelector('meta[property="og:image"]')?.content),
      ...Array.from(document.querySelectorAll("article img, main img, img"))
        .map((img) => img.currentSrc || img.src || "")
        .filter((src) => /^https?:\/\//.test(src)),
    ]
  ).slice(0, 20);

  return JSON.stringify(
    {
      schemaVersion: "1.0",
      adapter: "generic-page",
      kind: "generic-page",
      title,
      author,
      summary,
      body,
      commentTotal: "",
      comments: [],
      imageUrls,
      notes: ["generic-page extractor: extracted from meta/article/main selectors"],
    },
    null,
    2
  );
})()
