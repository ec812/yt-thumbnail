# YouTube Thumbnail Generator — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** A single-page web app that composites a YouTube thumbnail (1280×720) from a background image, gradient-clipped text, and a vertical dark overlay — with live preview and download.

**Architecture:** One `index.html` file with embedded CSS + JS. Canvas API handles all compositing. No build step, no dependencies. Deployed via GitHub Pages.

**Tech Stack:** Vanilla HTML/CSS/JS, Canvas API, `canvas.toBlob()` for export

---

## Composition Layers (bottom → top)

1. **Background image** — user-uploaded, scaled to fill 1280×720 (cover-style crop)
2. **Vertical gradient overlay** — transparent at top → semi-transparent black at bottom (adjustable)
3. **Text** — 2-3 lines, each line's fill is a linear gradient (clipped to text shape via `source-in` compositing)

---

## Tasks

### Task 1: Project scaffolding + GitHub Pages setup

**Objective:** Create repo, initial `index.html` with canvas element and basic layout

**Files:**
- Create: `index.html`
- Create: `style.css` (embedded in HTML)

**Steps:**
1. Create project directory and git init
2. Write `index.html` with:
   - `<canvas id="canvas" width="1280" height="720">` 
   - Control panel: file input for background, 3 text input rows, gradient color pickers, download button
   - Layout: canvas left/center, controls right sidebar (or stacked on mobile)
3. Basic CSS: dark theme, responsive-ish layout
4. Verify: open in browser, canvas renders as black 1280×720 rectangle

---

### Task 2: Background image upload + canvas rendering

**Objective:** Upload an image, draw it onto the canvas scaled to cover 1280×720

**Steps:**
1. ` FileReader` reads uploaded image into `Image` object
2. Draw function: calculate cover-scale (like CSS `background-size: cover`), center-crop, draw to canvas
3. Re-render on upload
4. Verify: upload any image → fills canvas, no distortion, edge-to-edge

---

### Task 3: Vertical gradient overlay

**Objective:** Draw a transparent→black gradient from top to bottom, between background and text layers

**Steps:**
1. After drawing background, create `ctx.createLinearGradient(0, 0, 0, 720)`
2. Add color stops: `0 → rgba(0,0,0,0)`, `1 → rgba(0,0,0,0.7)` (default, adjustable)
3. Fill full canvas with gradient
4. Verify: background image visible at top, gradually darkens toward bottom

---

### Task 4: Text input + basic rendering

**Objective:** Accept 2-3 lines of text and draw them on canvas

**Steps:**
1. Text input fields in control panel (line 1, line 2, optional line 3)
2. First line optionally preset to "直播一會" with a toggle/checkbox
3. Font: bold sans-serif, ~48-60px (tunable)
4. Draw each line centered horizontally, stacked vertically in the lower portion of the canvas
5. Default fill: white
6. Live re-render on every input change (debounced ~100ms)
7. Verify: type text → appears on canvas, centered, stacked

---

### Task 5: Gradient-clipped text effect

**Objective:** Replace solid white text fill with a linear gradient that's clipped to the text shape

**Steps:**
1. For each text line, create a temporary offscreen canvas
2. Draw the text in solid white on offscreen canvas
3. Set `offCtx.globalCompositeOperation = 'source-in'`
4. Draw a horizontal linear gradient over the text (default: warm orange→red, or user-configurable via color pickers)
5. Copy composited result back to main canvas at the correct position
6. Live update on color/position changes
7. Verify: text shows gradient fill, crisp edges, no bleed outside letterforms

---

### Task 6: Download/export

**Objective:** Save the composed canvas as a PNG file

**Steps:**
1. Button triggers `canvas.toBlob(blob => ...)` with `image/png`
2. Create object URL, trigger download via hidden `<a>` click
3. Filename: `thumbnail-{timestamp}.png`
4. Verify: click download → PNG saves, opens correctly, is 1280×720

---

### Task 7: UI polish + defaults

**Objective:** Make it actually pleasant to use

**Steps:**
1. Sensible defaults: gradient colors, overlay opacity, font size
2. Range sliders for: overlay opacity, font size, vertical text position
3. Quick-switch presets for text gradient (3-4 color combos)
4. Responsive: works on laptop screens (no need for mobile)
5. Visual feedback: thumbnail name after upload, character count on text inputs
6. Verify: full workflow end-to-end — upload bg, type text, adjust, download

---

### Task 8: GitHub Pages deploy

**Objective:** Push to GitHub, enable Pages, verify live

**Steps:**
1. Create GitHub repo via `gh repo create`
2. Push `index.html` to `main`
3. Enable GitHub Pages (source: main branch)
4. Verify: live URL loads and works
