# YouTube Thumbnail Generator

A single-file web app for composing YouTube thumbnails with layered compositing, gradient-clipped text, stroke, shadow, and in-browser AI background removal.

**Live:** Deployed via GitHub Pages

## Features

- **Layers** — stack background, image, color, and text layers; reorder, show/hide, lock, and delete from the Layers panel
- **Background layer** — upload any image, drag to reposition, cover-scaled to 1280×720, with adjustable overlay gradient
- **Image layers** — add cutouts or overlays with position, scale, stroke, shadow, opacity, and blending mode; drag on canvas to move
- **Color layers** — fill the whole canvas with a solid color, with adjustable opacity and 16 Photoshop-style blending modes (Multiply, Screen, Overlay, Color Dodge, Hard Light, Hue, Luminosity, …)
- **AI background removal** — one-click cutout via `briaai/RMBG-1.4` (runs in browser, model cached after first download)
- **Text layers** — 3 lines, Noto Sans TC font, with a 直播一會 checkbox preset (renders line 1 in solid white)
- **Gradient text** — two-color linear gradient clipped to text glyphs, adjustable angle (0–360°), 4 presets
- **Stroke & shadow** — per text and image layer
- **Adjustments** — font size (20–120px), line height (1.0–3.0), vertical text position
- **Save settings** — persist text/style controls to `localStorage` and auto-load on next visit
- **Save & load project** — auto-save to `localStorage` plus manual Save, and Export/Import as a `.json` file
- **Export** — download as 1280×720 PNG (all visible layers)

## Save & Load

- **Auto-save** — your project saves automatically 2 seconds after the last change
- **Save button** — explicit save with size feedback
- **Export/Import** — download your project as a `.json` file, re-import on any machine
- **Browser storage** — projects under ~4MB save to browser storage automatically; larger projects need Export/Import

All layers, images, text, effects, and eraser modifications are preserved.

## Default Style

Out-of-the-box text styling (also restored by **Reset to defaults**):

| Setting | Default |
|---------|---------|
| Gradient | Sunset (`#fad126` → `#ff544f`) |
| Gradient angle | 90° |
| Stroke | 8px black |
| Shadow | 0px / 0px offset, 3px blur, white |
| Font size | 96px |
| Line height | 1.2 |
| Vertical position | 93% |
| Overlay darkness | 70% |
| Overlay start | 65% |

Sample text: `BUILD AN APP` / `IN 10 MINUTES`

## Usage

1. Open `index.html` in a browser (or use the GitHub Pages deployment)
2. Select a layer in the **Layers** panel to edit it
3. Upload a background image (optional — defaults to solid black)
4. Add **+ Image** or **+ Text** layers as needed
5. For image layers, use **Remove background** to create a cutout (first run downloads ~45MB model)
6. Drag image/background layers on the canvas to reposition
7. Adjust gradient, stroke, shadow, and layout controls
8. Click **Save settings** to remember your style preferences
9. Click **Download** to save the thumbnail

## Tech Stack

- Vanilla HTML/CSS/JS — no build step
- Canvas API for all compositing
- Google Fonts CDN for Noto Sans TC
- `@huggingface/transformers` v3 (jsDelivr ESM) for in-browser background removal
- `localStorage` for settings persistence
- GitHub Pages for hosting

## Project Structure

```
index.html          # The entire app (HTML + CSS + JS)
docs/plans/         # Implementation plans
README.md           # This file
AGENTS.md           # AI agent context
```
