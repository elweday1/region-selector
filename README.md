# region-selector

A unified region capture tool for Wayland.

## Features

- **Screenshot** - Capture a region and save to file + clipboard
- **OCR** - Extract text from a region using Tesseract
- **Search** - Upload region to Google Lens for reverse search
- **Record** - Record a screen region (auto-saves previous recording)
- **Stop** - Stop active recording and show saved file location

## Usage

```bash
region-selector screenshot  # Default action
region-selector ocr
region-selector search
region-selector record
region-selector stop       # Stop active recording
```

## Installation

### 1. Install Dependencies

**Required:**
```bash
# Arch Linux
sudo pacman -S slurp grim wl-clipboard wf-recorder libnotify

# Debian/Ubuntu
sudo apt install slurp grim wl-clipboard wf-recorder libnotify
```

**Optional:**
```bash
# Arch Linux
sudo pacman -S tesseract tesseract-data-eng curl

# Debian/Ubuntu
sudo apt install tesseract tesseract-ocr-eng tesseract-data-eng curl
```

### 2. Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/region-selector/main/region-selector.sh -o ~/.local/bin/region-selector.sh
chmod +x ~/.local/bin/region-selector.sh
```

Ensure `~/.local/bin` is in your PATH.

### 3. Configure Keybinds

Add to your niri config (e.g., `~/.config/niri/config.d/70-binds.kdl`):

```kdl
Mod+S { spawn "~/.local/bin/region-selector.sh" "screenshot"; }
Mod+R { spawn "~/.local/bin/region-selector.sh" "record"; }
Mod+O { spawn "~/.local/bin/region-selector.sh" "ocr"; }
Mod+G { spawn "~/.local/bin/region-selector.sh" "search"; }
Mod+X { spawn "~/.local/bin/region-selector.sh" "stop"; }
```

Restart niri to apply.

## Dependencies

### Required
- [slurp](https://github.com/emersion/slurp) - Region selection
- [grim](https://sr.ht/~emersion/grim/) - Screenshot capture
- [wl-copy](https://github.com/bugaevc/wl-copy) - Clipboard
- [wf-recorder](https://github.com/ammen99/wf-recorder) - Screen recording
- [notify-send](https://man.archlinux.org/man/notify-send.1) - Notifications (libnotify)

### Optional
- [tesseract](https://github.com/tesseract-ocr/tesseract) + `tesseract-data-eng` - OCR
- [curl](https://curl.se/) - Image upload
- `xdg-open` compatible app - File/URL opening

## File Locations

| Type | Location |
|------|----------|
| Screenshots | `~/Pictures/Screenshots/` |
| Recordings | `~/Videos/recordings/` |
| Temp files | `/tmp/region-selector/` |

## How It Works

### Screenshot
1. User draws region with slurp
2. grim captures the region to file and pipe
3. Image copied to clipboard via wl-copy
4. Notification shown with Open/Copy Path actions

### OCR
1. User draws region with slurp
2. grim captures to temp file
3. tesseract extracts text
4. Text copied to clipboard
5. Truncated preview shown in notification (first 200 chars)

### Search
1. User draws region with slurp
2. grim captures to temp file
3. Image uploaded to catbox.moe
4. Browser opens Google Lens search with uploaded URL

### Record
1. If wf-recorder already running: auto-stop it and show saved file location
2. Start wf-recorder in background
3. Show "Recording..." notification with Stop button
4. On stop: kill wf-recorder, show saved notification
5. Notification offers Open (playback) or Folder actions

### Stop
1. Check if wf-recorder is running
2. If yes: stop it and show saved file location with Open/Folder options

## Notifications

All actions use libnotify with action buttons:

| Action | Notification | Actions |
|--------|--------------|---------|
| screenshot | "Screenshot saved" | Open, Copy Path |
| ocr | "OCR Complete" + text preview | (none) |
| search | "Search Error" on failure | (auto-opens browser) |
| record | (if running) "Recording saved" | Open, Folder |
| record | "Recording..." | Stop |
| record | "Recording saved" | Open, Folder |
| stop | "Recording saved" | Open, Folder |

## Exit Codes

- `0` - Success
- `1` - No region selected or error

## Notes

- Starting a new recording auto-saves the previous one
- Calling `record` while recording saves the current and exits (no new recording)
- Use `stop` to explicitly save and stop without starting new
- Temp OCR/search images are stored in `/tmp/region-selector/`
- Screenshots and recordings use timestamp naming: `ss-YYYYMMDD-HHMMSS.png`, `rec-YYYYMMDD-HHMMSS.mkv`
