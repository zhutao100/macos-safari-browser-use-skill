// Ready-to-copy Safari DOM summary expression for scripts/safari js-json.
// Usage:
//   macos-safari-browser-use/scripts/safari js-json "$(cat macos-safari-browser-use/assets/js/page-summary.js)"
//
// This expression is read-only. It does not access cookies, storage, or credentials.
(() => ({
  title: document.title,
  url: location.href,
  lang: document.documentElement.lang || null,
  description: document.querySelector('meta[name="description"]')?.content || null,
  headings: Array.from(document.querySelectorAll('h1,h2,h3')).slice(0, 40).map((h, index) => ({
    index: index + 1,
    level: h.tagName.toLowerCase(),
    text: h.textContent.trim().replace(/\s+/g, ' '),
  })),
  links: Array.from(document.querySelectorAll('a[href]')).slice(0, 80).map((a, index) => ({
    index: index + 1,
    text: a.textContent.trim().replace(/\s+/g, ' ').slice(0, 160),
    href: a.href,
  })),
  textPreview: (document.body?.innerText || '').trim().replace(/\s+/g, ' ').slice(0, 4000),
}))()
