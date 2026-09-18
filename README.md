# YouTube Thumbnail Generator

A single-file web app for composing YouTube thumbnails with gradient-clipped text, stroke, shadow, and background image manipulation.

**Live:** Deploy via GitHub Pages — just push `index.html`.

## Features

- **Background image** — upload any image, drag to reposition, cover-scaled to 1280×720
- **Text** — 3 lines, Noto Sans TC font, with a 直播一會 checkbox preset (renders in solid white)
- **Gradient text** — two-color linear gradient clipped to text glyphs, adjustable angle (0–360°)
- **Stroke** — adjustable width and color, drawn behind gradient fill
- **Shadow** — X/Y offset, blur radius, and color picker
- **Overlay** — transparent-to-black vertical gradient between background and text
- **Adjustments** — font size (20–120px), line height (1.0–3.0), vertical text position
- **Export** — download as 1280×720 PNG

## Usage

1. Open `index.html` in a browser (or deploy to GitHub Pages)
2. Upload a background image (optional — defaults to solid black)
3. Type your text lines
4. Adjust gradient, stroke, shadow, and layout controls
5. Click **Download** to save the thumbnail

## Tech Stack

- Vanilla HTML/CSS/JS — no build step, no dependencies
- Canvas API for all compositing
- Google Fonts CDN for Noto Sans TC
- GitHub Pages for hosting

## Project Structure

```
index.html          # The entire app (HTML + CSS + JS)
docs/plans/         # Implementation plans
README.md           # This file
AGENTS.md           # AI agent context
```

## Deployment

```bash
# Create repo and push
gh repo create yt-thumbnail-generator --public --source=. --push

# Enable GitHub Pages
gh api repos/{owner}/yt-thumbnail-generator/pages -f build_type=legacy -f source.branch=main
```
