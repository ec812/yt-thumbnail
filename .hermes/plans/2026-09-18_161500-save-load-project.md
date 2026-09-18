# Save/Load Project — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Let users save and restore their full thumbnail project (layers, images, text, all settings) to/from localStorage, with a file export/import fallback for large projects.

**Current context:** The app already saves slider/control values to localStorage via `SETTINGS_KEY = "yt-thumbnail-generator:settings"`, but this only stores control widget values — NOT layer state, images, or eraser modifications. Images are `HTMLImageElement`/`HTMLCanvasElement` objects that aren't JSON-serializable.

**Architecture:** Serialize each layer to a plain JSON object, converting images to data URLs (`canvas.toDataURL()`). Store the serialized state in localStorage with a size check (localStorage cap ~5MB). If the project exceeds localStorage, prompt the user to export as a `.json` file instead. On load, reconstruct images from data URLs via `new Image()` with `src = dataURL`. Auto-save debounced (2s idle), plus explicit Save/Load/Export/Import buttons.

---

## Key Design Decisions

**Why data URLs, not IndexedDB?**
- Data URLs work with the existing localStorage pattern and are simpler to reason about
- IndexedDB would be more robust for large images but adds complexity (async API, schema migration) that isn't justified for this use case
- If a project is too large for localStorage, we fall back to file export/import

**Why not just expand the existing settings save?**
- The existing `readSettings()` only reads DOM control values — it doesn't know about layers, images, or erase state
- A separate project-level save system is cleaner and avoids coupling

**Size budget:**
- localStorage limit: ~5MB (varies by browser)
- A 1280×720 PNG as data URL: ~200KB–2MB depending on content
- A 1920×1080 photo as data URL: ~500KB–3MB
- Budget: ~3MB for project data (leaving room for the existing settings save)

---

## Serialization Format

```json
{
  "version": 1,
  "layers": [
    {
      "id": "layer_abc",
      "type": "background",
      "visible": true,
      "locked": false,
      "name": "Background",
      "imageDataURL": "data:image/png;base64,...",
      "src": "original-filename.jpg",
      "x": 0, "y": 0, "scale": 1,
      "overlay": 70, "overlayStart": 65
    },
    {
      "id": "layer_def",
      "type": "text",
      "visible": true,
      "locked": false,
      "name": "Text",
      "text": ["BUILD AN APP", "IN 10 MINUTES", ""],
      "presetCjk": false,
      "color1": "#fad126", "color2": "#ff544f",
      "gradientAngle": 90,
      "fontSize": 96, "lineHeight": 1.2, "textY": 93,
      "strokeWidth": 8, "strokeColor": "#000000",
      "shadowX": 0, "shadowY": 0, "shadowBlur": 3, "shadowColor": "#ffffff"
    },
    {
      "id": "layer_ghi",
      "type": "image",
      "visible": true,
      "locked": false,
      "name": "Person",
      "imageDataURL": "data:image/png;base64,...",
      "eraseDataURL": "data:image/png;base64,...",
      "src": "photo.jpg",
      "x": 100, "y": 50, "scale": 0.8,
      "strokeWidth": 3, "strokeColor": "#00ff00",
      "shadowX": 5, "shadowY": 5, "shadowBlur": 10, "shadowColor": "#000000",
      "eraseRadius": 20
    }
  ],
  "selectedId": "layer_def",
  "savedAt": "2026-09-18T16:00:00Z"
}
```

**Field mapping per layer type:**

| Field | background | text | image |
|-------|-----------|------|-------|
| id | ✓ | ✓ | ✓ |
| type | ✓ | ✓ | ✓ |
| visible/locked/name | ✓ | ✓ | ✓ |
| imageDataURL | ✓ (from image) | — | ✓ (from image) |
| eraseDataURL | — | — | ✓ (from eraseCanvas if exists) |
| src | ✓ | — | ✓ |
| x, y, scale | ✓ | — | ✓ |
| overlay, overlayStart | ✓ | — | — |
| text (array) | — | ✓ | — |
| presetCjk | — | ✓ | — |
| color1, color2, gradientAngle | — | ✓ | — |
| fontSize, lineHeight, textY | — | ✓ | — |
| strokeWidth/Color | ✓ (text only) | ✓ | ✓ |
| shadowX/Y/Blur/Color | — | ✓ | ✓ |
| eraseRadius | — | — | ✓ |

---

## Tasks

### Task 1: Serialization — `serializeProject()` and `deserializeProject()`

**Objective:** Convert the live layers array to a JSON-safe object and back.

**Files:**
- Modify: `index.html` (script block)

**Step 1: Write `serializeProject()`**

Add after the `cloneLayer` function (~line 2344):

```javascript
function imageToDataURL(img) {
  if (!img) return null;
  if (img.tagName === "CANVAS") {
    return img.toDataURL("image/png");
  }
  // HTMLImageElement — draw to offscreen canvas to get data URL
  var c = document.createElement("canvas");
  c.width = img.naturalWidth || img.width;
  c.height = img.naturalHeight || img.height;
  c.getContext("2d").drawImage(img, 0, 0);
  return c.toDataURL("image/png");
}

function serializeProject() {
  return {
    version: 1,
    layers: layers.map(function (layer) {
      var s = {
        id: layer.id,
        type: layer.type,
        visible: layer.visible,
        locked: layer.locked,
        name: layer.name
      };
      if (layer.type === "background" || layer.type === "image") {
        s.imageDataURL = imageToDataURL(layer.image);
        s.src = layer.src || null;
        s.x = layer.x;
        s.y = layer.y;
        s.scale = layer.scale;
      }
      if (layer.type === "background") {
        s.overlay = layer.overlay;
        s.overlayStart = layer.overlayStart;
      }
      if (layer.type === "text") {
        s.text = layer.text.slice();
        s.presetCjk = layer.presetCjk;
        s.color1 = layer.color1;
        s.color2 = layer.color2;
        s.gradientAngle = layer.gradientAngle;
        s.fontSize = layer.fontSize;
        s.lineHeight = layer.lineHeight;
        s.textY = layer.textY;
        s.strokeWidth = layer.strokeWidth;
        s.strokeColor = layer.strokeColor;
        s.shadowX = layer.shadowX;
        s.shadowY = layer.shadowY;
        s.shadowBlur = layer.shadowBlur;
        s.shadowColor = layer.shadowColor;
      }
      if (layer.type === "image") {
        s.strokeWidth = layer.strokeWidth;
        s.strokeColor = layer.strokeColor;
        s.shadowX = layer.shadowX;
        s.shadowY = layer.shadowY;
        s.shadowBlur = layer.shadowBlur;
        s.shadowColor = layer.shadowColor;
        s.eraseRadius = layer.eraseRadius;
        if (layer.eraseCanvas && layer.eraseCanvas !== layer.image) {
          s.eraseDataURL = layer.eraseCanvas.toDataURL("image/png");
        }
      }
      return s;
    }),
    selectedId: selectedLayer ? selectedLayer.id : null,
    savedAt: new Date().toISOString()
  };
}
```

**Step 2: Write `deserializeProject(data)`**

```javascript
function loadImage(url) {
  return new Promise(function (resolve) {
    if (!url) { resolve(null); return; }
    var img = new Image();
    img.onload = function () { resolve(img); };
    img.onerror = function () { resolve(null); };
    img.src = url;
  });
}

async function deserializeProject(data) {
  if (!data || !data.layers) return false;

  var newLayers = [];
  for (var i = 0; i < data.layers.length; i++) {
    var s = data.layers[i];
    var layer;

    if (s.type === "background") {
      layer = createBackgroundLayer();
    } else if (s.type === "text") {
      layer = createTextLayer();
    } else if (s.type === "image") {
      layer = createImageLayer();
    } else {
      continue;
    }

    // Common fields
    layer.id = s.id || layer.id;
    layer.visible = s.visible !== undefined ? s.visible : true;
    layer.locked = s.locked || false;
    layer.name = s.name || layer.name;

    // Load images asynchronously
    if (s.type === "background" || s.type === "image") {
      layer.image = await loadImage(s.imageDataURL);
      layer.src = s.src;
      layer.x = s.x || 0;
      layer.y = s.y || 0;
      layer.scale = s.scale || 1;
    }

    if (s.type === "background") {
      layer.overlay = s.overlay !== undefined ? s.overlay : DEFAULTS.overlay;
      layer.overlayStart = s.overlayStart !== undefined ? s.overlayStart : DEFAULTS.overlayStart;
    }

    if (s.type === "text") {
      layer.text = s.text || ["", "", ""];
      layer.presetCjk = s.presetCjk || false;
      layer.color1 = s.color1 || DEFAULTS.color1;
      layer.color2 = s.color2 || DEFAULTS.color2;
      layer.gradientAngle = s.gradientAngle !== undefined ? s.gradientAngle : DEFAULTS.gradientAngle;
      layer.fontSize = s.fontSize || DEFAULTS.fontSize;
      layer.lineHeight = s.lineHeight || DEFAULTS.lineHeight;
      layer.textY = s.textY !== undefined ? s.textY : DEFAULTS.textY;
      layer.strokeWidth = s.strokeWidth || 0;
      layer.strokeColor = s.strokeColor || "#000000";
      layer.shadowX = s.shadowX || 0;
      layer.shadowY = s.shadowY || 0;
      layer.shadowBlur = s.shadowBlur || 0;
      layer.shadowColor = s.shadowColor || "#000000";
    }

    if (s.type === "image") {
      layer.strokeWidth = s.strokeWidth || 0;
      layer.strokeColor = s.strokeColor || "#000000";
      layer.shadowX = s.shadowX || 0;
      layer.shadowY = s.shadowY || 0;
      layer.shadowBlur = s.shadowBlur || 0;
      layer.shadowColor = s.shadowColor || "#000000";
      layer.eraseRadius = s.eraseRadius || 20;
      // Restore erase state if it differs from the main image
      if (s.eraseDataURL) {
        var eraseImg = await loadImage(s.eraseDataURL);
        if (eraseImg) {
          var ec = document.createElement("canvas");
          ec.width = eraseImg.naturalWidth;
          ec.height = eraseImg.naturalHeight;
          ec.getContext("2d").drawImage(eraseImg, 0, 0);
          layer.eraseCanvas = ec;
          layer._eraseSource = ec;
        }
      }
    }

    newLayers.push(layer);
  }

  if (newLayers.length === 0) return false;

  layers = newLayers;

  // Restore selection
  if (data.selectedId) {
    var found = layers.find(function (l) { return l.id === data.selectedId; });
    if (found) selectLayer(found);
    else selectLayer(layers[0]);
  } else {
    selectLayer(layers[0]);
  }

  // Sync controls to selected layer
  syncControlsFromLayer(selectedLayer);
  refreshLayerPanel();
  undoStack.length = 0;
  redoStack.length = 0;
  updateUndoButtons();
  render();
  return true;
}
```

**Step 3: Verify**

Open `index.html` in browser, open console, run:
```javascript
var p = serializeProject();
console.log("layers:", p.layers.length, "size:", JSON.stringify(p).length);
```
Expected: layers: 2 size: ~200 (no images loaded, so dataURLs are null)

Run:
```javascript
var data = JSON.parse(JSON.stringify(p));
layers = [];
await deserializeProject(data);
```
Expected: 2 layers restored, controls sync to selected layer, canvas renders

---

### Task 2: localStorage save/load with size check

**Objective:** Save the full project to localStorage, with a size guard.

**Files:**
- Modify: `index.html` (script block)

**Step 1: Add constants and save/load functions**

```javascript
var PROJECT_KEY = "yt-thumbnail-generator:project";
var MAX_PROJECT_SIZE = 4 * 1024 * 1024; // 4MB safety margin

function saveProject() {
  try {
    var data = serializeProject();
    var json = JSON.stringify(data);
    if (json.length > MAX_PROJECT_SIZE) {
      return { ok: false, reason: "too_large", size: json.length };
    }
    localStorage.setItem(PROJECT_KEY, json);
    return { ok: true, size: json.length };
  } catch (e) {
    return { ok: false, reason: e.message || "unknown" };
  }
}

function loadSavedProject() {
  try {
    var raw = localStorage.getItem(PROJECT_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (e) {
    return null;
  }
}

function hasSavedProject() {
  try {
    return !!localStorage.getItem(PROJECT_KEY);
  } catch (e) {
    return false;
  }
}
```

**Step 2: Add auto-save with debounce**

```javascript
var autoSaveTimer = null;
var autoSaveStatusEl = null; // will be set in init

function scheduleAutoSave() {
  if (autoSaveTimer) clearTimeout(autoSaveTimer);
  autoSaveTimer = setTimeout(function () {
    var result = saveProject();
    if (autoSaveStatusEl) {
      if (result.ok) {
        autoSaveStatusEl.textContent = "Auto-saved";
        autoSaveStatusEl.style.color = "";
      } else if (result.reason === "too_large") {
        autoSaveStatusEl.textContent = "Project too large to auto-save — use Export";
        autoSaveStatusEl.style.color = "#ff9800";
      }
    }
  }, 2000);
}
```

**Step 3: Hook auto-save into all state-changing actions**

Add `scheduleAutoSave()` call at the end of:
- `render()` (covers slider changes, text edits)
- `pushUndo()` (covers layer add/delete/reorder, erase, BG removal)
- Image upload callbacks
- Layer visibility/lock toggle
- Preset selection

**Step 4: Auto-load on page init**

At the end of the existing `init()` or DOMContentLoaded handler, after the current `loadSavedSettings()` call:

```javascript
// Load saved project if available
var savedProject = loadSavedProject();
if (savedProject) {
  await deserializeProject(savedProject);
  if (autoSaveStatusEl) {
    autoSaveStatusEl.textContent = "Loaded saved project";
  }
}
```

**Step 5: Verify**

1. Load the page, add an image layer, type some text
2. Wait 3 seconds for auto-save
3. Reload the page
4. Expected: all layers, images, and text are restored

---

### Task 3: Export/Import as .json file

**Objective:** Let users download their project as a `.json` file and re-import it — bypassing localStorage limits.

**Files:**
- Modify: `index.html` (HTML + script block)

**Step 1: Add Export button**

In the Export section of the HTML (near the Download button), add:

```html
<div class="row" style="margin-top: 8px">
  <button class="ghost" type="button" id="exportProject">Export project (.json)</button>
</div>
<div class="row">
  <button class="ghost" type="button" id="importProject">Import project (.json)</button>
  <input type="file" id="importProjectInput" accept=".json" style="display:none" />
</div>
<div id="projectStatus" class="char"></div>
```

**Step 2: Add export function**

```javascript
function exportProject() {
  var data = serializeProject();
  var json = JSON.stringify(data, null, 2);
  var blob = new Blob([json], { type: "application/json" });
  var url = URL.createObjectURL(blob);
  var a = document.createElement("a");
  a.href = url;
  a.download = "thumbnail-project-" + Date.now() + ".json";
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
  if (projectStatusEl) {
    projectStatusEl.textContent = "Project exported";
  }
}
```

**Step 3: Add import function**

```javascript
function importProject(file) {
  var reader = new FileReader();
  reader.onload = async function (e) {
    try {
      var data = JSON.parse(e.target.result);
      var ok = await deserializeProject(data);
      if (ok) {
        scheduleAutoSave(); // save to localStorage too
        if (projectStatusEl) {
          projectStatusEl.textContent = "Project imported";
        }
      } else {
        if (projectStatusEl) {
          projectStatusEl.textContent = "Invalid project file";
          projectStatusEl.style.color = "#f44336";
        }
      }
    } catch (err) {
      if (projectStatusEl) {
        projectStatusEl.textContent = "Could not read project file";
        projectStatusEl.style.color = "#f44336";
      }
    }
  };
  reader.readAsText(file);
}
```

**Step 4: Wire buttons**

```javascript
document.getElementById("exportProject").addEventListener("click", exportProject);
var importInput = document.getElementById("importProjectInput");
document.getElementById("importProject").addEventListener("click", function () {
  importInput.click();
});
importInput.addEventListener("change", function () {
  if (importInput.files.length > 0) {
    importProject(importInput.files[0]);
    importInput.value = "";
  }
});
```

**Step 5: Verify**

1. Create a project with text + image layers
2. Click "Export project" → `.json` file downloads
3. Reset the page
4. Click "Import project" → select the `.json` file
5. Expected: full project restored, all layers, images, text, settings

---

### Task 4: Manual Save button + localStorage quota display

**Objective:** Explicit save button with feedback, and show how much localStorage is used.

**Files:**
- Modify: `index.html` (HTML + script block)

**Step 1: Add Save button + status to the Export section**

```html
<div class="row" style="margin-top: 8px">
  <button class="accent" type="button" id="saveProject">Save project</button>
</div>
<div id="projectStatus" class="char"></div>
```

**Step 2: Wire Save button**

```javascript
var projectStatusEl = document.getElementById("projectStatus");

document.getElementById("saveProject").addEventListener("click", function () {
  var result = saveProject();
  if (result.ok) {
    var kb = (result.size / 1024).toFixed(0);
    projectStatusEl.textContent = "Saved (" + kb + " KB)";
    projectStatusEl.style.color = "";
  } else if (result.reason === "too_large") {
    var mb = (result.size / (1024 * 1024)).toFixed(1);
    projectStatusEl.textContent = "Too large for browser (" + mb + " MB) — use Export";
    projectStatusEl.style.color = "#ff9800";
  } else {
    projectStatusEl.textContent = "Save failed: " + result.reason;
    projectStatusEl.style.color = "#f44336";
  }
});
```

**Step 3: Show quota on load**

```javascript
function getStorageUsage() {
  try {
    var total = 0;
    for (var key in localStorage) {
      if (localStorage.hasOwnProperty(key)) {
        total += localStorage.getItem(key).length * 2; // UTF-16
      }
    }
    return total;
  } catch (e) {
    return 0;
  }
}

// In init, after loading:
if (autoSaveStatusEl) {
  var used = getStorageUsage();
  var kb = (used / 1024).toFixed(0);
  autoSaveStatusEl.textContent = "Storage used: " + kb + " KB";
}
```

**Step 4: Verify**

1. Load page, create project
2. Click "Save project"
3. Expected: status shows "Saved (XXX KB)"
4. Reload page
5. Expected: project restored, status shows "Loaded saved project"

---

### Task 5: Update README.md

**Objective:** Document the save/load feature.

**Files:**
- Modify: `README.md`

**Add a section:**

```markdown
## Save & Load

- **Auto-save** — your project saves automatically 2 seconds after the last change
- **Save button** — explicit save with size feedback
- **Export/Import** — download your project as a `.json` file, re-import on any machine
- **Browser storage** — projects under ~4MB save to browser storage automatically; larger projects need Export/Import

All layers, images, text, effects, and eraser modifications are preserved.
```

---

## Risks and Tradeoffs

1. **localStorage size limit (~5MB)** — Large photos as data URLs can exceed this. The export/import fallback handles this, but users may not realize they need it until they hit the limit. The quota display in Task 4 mitigates this.

2. **Data URL performance** — `canvas.toDataURL("image/png")` is synchronous and can take 100ms+ for large images. For auto-save this is fine (debounced 2s). For immediate feedback on Save, consider showing a brief "Saving..." state.

3. **Eraser canvas restoration** — The eraser modifies the image in-place. We save the eraseCanvas separately so it can be restored. If the eraseCanvas is the same reference as the image (no erasing happened), we skip it to save space.

4. **Image element vs canvas** — After deserialization, all images are `HTMLImageElement` (from `new Image()`). The eraseCanvas remains an `HTMLCanvasElement`. This matches the existing layer model where `layer.image` can be either type.

5. **No conflict resolution** — If the user has the same project open in two tabs, they'll overwrite each other's localStorage. This is acceptable for a single-user tool.

6. **Existing settings save** — The current `SETTINGS_KEY` save stores control values independently. The new project save supersedes it for project data, but we keep the settings save for backward compatibility (it's harmless and handles the case where someone has saved settings but no project yet).
