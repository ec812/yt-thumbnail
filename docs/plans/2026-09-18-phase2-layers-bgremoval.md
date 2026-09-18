# Phase 2: Layers + Background Removal — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Add a layers system and AI-powered background removal to the YouTube thumbnail generator, running entirely in the browser on GitHub Pages for free.

**Architecture:** Refactor the current single-canvas render loop into a layer-based compositing system. Add ONNX-based background removal via `@huggingface/transformers` (v3) which downloads models from HuggingFace Hub at runtime (CORS-enabled, free, no API key).

**Tech Stack:**
- `@huggingface/transformers` v3 — CDN import (esm.sh), handles ONNX Runtime + model download
- Model: `briaai/RMBG-1.4` (ONNX quantized, ~45MB, downloaded once and cached by browser)
- Canvas API — layer compositing (unchanged)
- Vanilla JS — layer management UI

**Model hosting:** No hosting needed. `@huggingface/transformers` fetches models from HuggingFace Hub (`huggingface.co`) at runtime. HuggingFace serves with CORS headers. Browser caches the model in IndexedDB after first download. Zero cost, zero server.

---

## Architecture Overview

### Layer Data Model

```js
{
  id: "layer_abc123",
  type: "image",           // "background" | "image" | "text"
  visible: true,
  locked: false,
  name: "Person cutout",

  // image/background layers
  image: ImageBitmap,      // the loaded image (with BG removed if applicable)
  x: 0, y: 0,             // position offset (for drag)
  scale: 1,               // future: resize handle

  // text layers
  text: ["Line 1", "Line 2"],
  fontSize: 72,
  lineHeight: 1.4,
  textY: 62,              // vertical position %
  color1: "#ffd54f",
  color2: "#ff3d00",
  gradientAngle: 0,
  strokeWidth: 0,
  strokeColor: "#000000",
  shadowX: 0, shadowY: 0, shadowBlur: 0, shadowColor: "#000000",
  presetCjk: false,       // 直播一會 white-only line
}
```

### Render Pipeline

```
for each layer (bottom to top):
  if not visible → skip
  switch layer.type:
    "background" → drawBackground(layer)     // fill + cover-scale + offset
    "image"      → drawImage(layer)          // draw at position with transparency
    "text"       → drawText(layer)           // gradient-clipped text (existing logic)
```

The canvas clears once, then layers composite on top of each other using standard Canvas 2D drawing.

---

## Tasks

### Task 1: Layer data model + render pipeline refactor

**Objective:** Extract current rendering into a layer-based system. Existing behavior stays identical — the default state has one background layer and one text layer.

**Files:**
- Modify: `index.html` (script block)

**Steps:**
1. Define `layers` array with default state: one background layer (type: "background", currently null image) + one text layer (carries all current text controls)
2. Extract `drawBackground()` to accept a layer object instead of global vars
3. Extract `drawText()` to accept a layer object instead of global vars
4. Rewrite `render()` to clear canvas once, then iterate `layers` bottom-to-top calling the appropriate draw function
5. Wire existing control panel to modify the first text layer's properties
6. Verify: existing thumbnail tool works identically — same controls, same output

---

### Task 2: Layer panel UI

**Objective:** Add a layer management sidebar/panel below or beside the controls.

**Steps:**
1. HTML: Add `<div id="layerPanel">` with header "Layers" + "Add Layer" button
2. Each layer renders as a row: visibility eye icon ( toggle), lock icon (toggle), layer name, type badge, delete button
3. Clicking a layer selects it — control panel switches to show that layer's properties
4. Drag handle on left side for reorder (HTML5 drag API or pointer events)
5. Active layer highlighted in the panel
6. "Add Layer" button adds a new empty image layer or text layer (prompt or default)
7. Verify: can see layers, toggle visibility, select layers, reorder by drag

---

### Task 3: Layer controls wiring

**Objective:** Control panel dynamically shows properties of the selected layer.

**Steps:**
1. When a text layer is selected → show text controls (inputs, gradient, stroke, shadow, adjust)
2. When an image layer is selected → show image controls (position X/Y, scale, "Remove BG" button)
3. When background layer is selected → show background controls (existing upload + drag)
4. Hide irrelevant controls per layer type
5. Changes to controls update the selected layer's data, then trigger render()
6. Verify: switch between layers, controls update, changes affect correct layer

---

### Task 4: Image layer upload

**Objective:** Upload an image as a new layer (on top of background).

**Steps:**
1. "Add Image Layer" button → file input → loads image into layer.image
2. New layer appears at top of layer stack, selected automatically
3. Image drawn at center of canvas by default
4. Drag to reposition (existing drag logic, adapted per-layer)
5. Layer named after filename
6. Verify: upload image → appears as new layer on top, can drag, shows in layer panel

---

### Task 5: ONNX background removal integration

**Objective:** Add "Remove BG" button on image layers that strips the background using AI.

**Steps:**
1. Add `@huggingface/transformers` via CDN `<script type="module">` or dynamic import
2. Implement `removeBackground(imageElement)` function:
   - Load `briaai/RMBG-1.4` model via `pipeline('image-segmentation', 'briaai/RMBG-1.4')`
   - First call: downloads model (~45MB quantized), subsequent calls use cache
   - Show loading indicator on the layer row while processing
   - Returns ImageBitmap with transparent background
3. "Remove BG" button on image layer triggers `removeBackground()`
4. Replace layer.image with the result
5. Re-render
6. Verify: upload photo of person → click Remove BG → background disappears → download still works

---

### Task 6: Model loading UX

**Objective:** Handle the model download gracefully.

**Steps:**
1. Show "Loading AI model..." progress bar on first use (model download ~45MB)
2. Cache status: show "AI ready" badge after first successful load
3. Error handling: if model fails to load, show error message, offer retry
4. Store model reference in module scope — only initialize once
5. Verify: first use shows loading, second use is instant, error state works

---

### Task 7: Layer delete + duplicate

**Objective:** Essential layer management operations.

**Steps:**
1. Delete button removes layer (with confirmation if layer has content)
2. Duplicate button copies layer with all properties
3. Cannot delete the last layer (minimum 1)
4. Verify: delete, duplicate, minimum-1 guard all work

---

### Task 8: Export composites all visible layers

**Objective:** Download button exports the full layer stack as PNG.

**Steps:**
1. Export logic already iterates layers — confirm it works with multiple layers
2. Filename includes timestamp (existing behavior)
3. Hidden layers excluded from export
4. Verify: 3 layers (bg + image + text) → export produces correct composite PNG

---

### Task 9: UI polish

**Objective:** Make the layer system feel professional.

**Steps:**
1. Layer panel collapsible
2. Layer reordering via drag-and-drop with visual indicator (drop zone highlight)
3. Selected layer gets a colored border on the canvas preview
4. Keyboard shortcuts: Delete key removes selected layer
5. Responsive: layer panel stacks below on narrow screens
6. Verify: full workflow — upload bg, add image layer, remove BG, add text layer, reorder, export

---

## Model Details

**Model:** `briaai/RMBG-1.4` (ONNX quantized)
- Size: ~45MB (8-bit quantized)
- License: bria-rmbg-1.4 license (free for commercial use)
- Quality: excellent for person/object segmentation
- First download: 5-15 seconds depending on connection
- Subsequent loads: instant (browser cache)
- Runs on: WebAssembly (all browsers) or WebGPU (Chrome/Edge)

**Why this model:**
- Non-gated (no API key needed)
- Good quality/size ratio
- Proven in browser (Xenova's demo uses it)
- ONNX format optimized for web inference

**Fallback:** If `briaai/RMBG-1.4` has issues, fall back to `Xenova/modnet` (~25MB, also good quality).
