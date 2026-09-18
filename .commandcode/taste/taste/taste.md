# Taste
- Keeps implementation plans as dated markdown files under `docs/plans/` (e.g. `docs/plans/2026-09-18-yt-thumbnail-generator.md`) and expects the agent to read the plan and implement the enumerated tasks. Confidence: 0.6
- For client-side persistence in browser tools, explicitly asks for `localStorage` with the state serialized as a simple array (fixed field order) rather than a keyed object or server-side storage. Confidence: 0.5
- Prefers self-contained single-file deliverables for small web tools — one `index.html` with embedded CSS and JS rather than split files or a build step. Confidence: 0.65
- Prefers dark UI styling for the apps/tools they request. Confidence: 0.6
- Wants git work scoped to a local `git init` + commit by default; publishing (creating a public repo, enabling Pages, pushing) should only happen when explicitly asked. Confidence: 0.55
- Expects feature additions to be additive and non-breaking — repeatedly asks that new controls work with the existing ones and that all existing functionality keep working, so extend with targeted edits rather than rewriting the file. Confidence: 0.6
- Prefers web fonts loaded from the Google Fonts CDN (with preconnect links) and pinned via a single font-family constant, rather than bundling font files or relying on system fonts. Confidence: 0.5
