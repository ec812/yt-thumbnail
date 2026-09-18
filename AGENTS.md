# AGENTS.md — YouTube Thumbnail Generator

## What This Is

Single-file web app (`index.html`) that composites YouTube thumbnails (1280×720) from a background image + styled text. Zero dependencies, no build step.

## Architecture

Everything lives in one `index.html` with embedded `<style>` and `<script>` blocks.

### Canvas Composition Layers (bottom → top)

1. **Background image** — user-uploaded, cover-scaled (fill + center crop), draggable
2. **Vertical gradient overlay** — transparent top → semi-transparent black bottom
3. **Text** — 2-3 lines, each rendered via offscreen canvas compositing

### Key Technical Patterns

**Gradient-clipped text** — the core visual effect:
- Draw text in white on an offscreen canvas
- Set `globalCompositeOperation = "source-in"`
- Fill with a linear gradient (angle-rotated through glyph bounding box)
- Composite back to main canvas

**Stroke rendering** — drawn on main canvas at `lineWidth = width * 2`, then gradient fill paints over the inner half, leaving a crisp outline.

**Shadow** — uses Canvas `shadow*` properties with `save/restore`. Applied to stroke when present, otherwise to gradient text.

**Background drag** — pointer events with `setPointerCapture`, coordinate conversion via `getBoundingClientRect`. Offsets clamped to keep image covering canvas.

**直播一會 preset** — when checkbox is on, line 1 renders as solid white (no gradient, but stroke and shadow still apply). Other lines keep full styling.

### Font

Always Noto Sans TC (loaded from Google Fonts CDN). `FONT_FAMILY` and `FONT_WEIGHT` constants + `fontString()` helper. `document.fonts.ready` hook re-renders after webfont loads.

### Controls

| Section | Controls |
|---------|----------|
| Background | Upload, drag to reposition, clear |
| Text | 3 input lines, 直播一會 checkbox |
| Text gradient | Color 1, Color 2, Angle (0–360°), 4 presets |
| Stroke | Width (0–24px), color |
| Shadow | X offset (−40..40), Y offset (−40..40), blur (0–60), color |
| Adjust | Font size (20–120px), line height (1.0–3.0), text X/Y position, overlay opacity, overlay start |
| Export | Download PNG |

### Export

`canvas.toBlob("image/png")` → object URL → hidden `<a>` click. Filename: `thumbnail-{timestamp}.png`.

## Making Changes

- **Add a control:** Add HTML in the appropriate `<fieldset>`, wire JS element ref + event listener in the `<script>` block, thread through `render()` and `reset()`
- **Change text rendering:** Modify `gradientClippedLine()` (offscreen canvas) or `drawText()` (main canvas placement)
- **Change background rendering:** Modify `drawBackground()` — note `bgOffsetX`/`bgOffsetY` for drag state
- **Add a new composition layer:** Insert between existing layers in `render()` function

## Common Pitfalls

- Canvas text won't repaint after webfont loads — always re-render in `document.fonts.ready` callback
- `measureText()` uses current `textBaseline` — if you change baseline for drawing, measurements shift
- `source-in` compositing is destructive — only use on offscreen canvas or after saving state
- Background drag offsets must be clamped so the image always covers the full 1280×720 canvas

## Testing

No test suite. Verification is manual via headless Chromium (Playwright):
1. Set controls programmatically via `setRange()` / `setText()` helpers
2. Render and screenshot
3. Visual inspection of the screenshot
