(() => {
  const selectors = [
    ".note-slider-box img",
    ".note-slider-img img",
    ".swiper-slide img",
    'img[src*="sns-webpic"]',
  ];

  for (const selector of selectors) {
    const candidates = Array.from(document.querySelectorAll(selector));
    for (const node of candidates) {
      const width = node.naturalWidth || node.clientWidth || 0;
      if (width >= 300) {
        node.click();
        return "clicked";
      }
    }
  }

  return "no-gallery-image";
})()
