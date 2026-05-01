#!/bin/bash
# region-selector - Unified region capture tool for Wayland
#
# Usage:
#   region-selector screenshot  - Take screenshot of selected region
#   region-selector ocr         - Extract text from selected region
#   region-selector search      - Search image via Google Lens
#   region-selector record      - Record selected region (auto-saves prev)
#   region-selector stop       - Stop active recording
#
# Dependencies:
#   - slurp, grim, wl-copy     (Wayland screenshot tools)
#   - wf-recorder               (screen recording)
#   - tesseract + tesseract-data-eng (OCR)
#   - curl                      (image upload to catbox.moe)
#
# Files:
#   Screenshots: ~/Pictures/Screenshots/
#   Recordings: ~/Videos/recordings/
#   Temp: /tmp/region-selector/

set -euo pipefail

RECORDINGS_DIR="$HOME/Videos/recordings"
SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
TEMP_DIR="/tmp/region-selector"

mkdir -p "$RECORDINGS_DIR" "$SCREENSHOTS_DIR" "$TEMP_DIR"

select_region() {
    slurp 2>/dev/null || {
        notify-send -a "RegionSelector" "No region selected"
        exit 1
    }
}

handle_notification_response() {
    local response="$1"
    shift

    for action in "$@"; do
        local key="${action%%=*}"
        local cmd="${action#*=}"
        if [ "$response" = "$key" ] && [ -n "$cmd" ]; then
            eval "$cmd"
            return 0
        fi
    done
    return 1
}

do_screenshot() {
    local region="$1"
    local file="$SCREENSHOTS_DIR/ss-$(date +%Y%m%d-%H%M%S).png"

    grim -g "$region" "$file"
    grim -g "$region" - | wl-copy

    local response
    response=$(notify-send -a "RegionSelector" -A "open=Open" -A "copy=Copy Path" "Screenshot saved" "$file" --action=open,copy)
    handle_notification_response "$response" \
        "open=xdg-open '$file'" \
        "copy=echo '$file' | wl-copy"
}

do_ocr() {
    local region="$1"

    if ! ls /usr/share/tessdata/eng.traineddata &>/dev/null 2>&1; then
        notify-send -a "RegionSelector" "OCR Error" "Please install tesseract-data-eng"
        exit 1
    fi

    grim -g "$region" "$TEMP_DIR/ocr.png" 2>/dev/null

    local text
    text=$(tesseract "$TEMP_DIR/ocr.png" stdout 2>/dev/null | wl-copy)

    local truncated
    truncated=$(echo "$text" | head -c 200 | sed 's/[[:space:]]*$//')
    if [ ${#text} -gt 200 ]; then
        truncated="${truncated}..."
    elif [ -z "$truncated" ]; then
        truncated="(empty)"
    fi

    notify-send -a "RegionSelector" "OCR Complete" "$truncated"
}

do_search() {
    local region="$1"

    grim -g "$region" "$TEMP_DIR/search.png" 2>/dev/null

    local upload_url
    upload_url=$(curl -sf -F "reqtype=fileupload" -F "fileToUpload=@$TEMP_DIR/search.png" https://catbox.moe/user/api.php)

    if [ -n "$upload_url" ]; then
        xdg-open "https://lens.google.com/uploadbyurl?url=${upload_url}"
    else
        notify-send -a "RegionSelector" "Search Error" "Failed to upload image"
    fi
}

do_record() {
    local region="$1"
    local file="$RECORDINGS_DIR/rec-$(date +%Y%m%d-%H%M%S).mkv"

    wf-recorder --geometry "$region" -f "$file" &
    sleep 0.3

    local response
    response=$(notify-send -a "RegionSelector" -A "stop=Stop" "Recording..." --action=stop)
    case "$response" in
        "stop")
            pkill -x wf-recorder
            sleep 0.5
            ;;
    esac

    local response2
    response2=$(notify-send -a "RegionSelector" -A "open=Open" -A "folder=Folder" "Recording saved" "$file" --action=open,folder)
    handle_notification_response "$response2" \
        "open=xdg-open '$file'" \
        "folder=xdg-open '$RECORDINGS_DIR'"
}

main() {
    local action="${1:-screenshot}"

    if [ "$action" = "stop" ]; then
        if pgrep -x wf-recorder > /dev/null 2>&1; then
            pkill -x wf-recorder
            sleep 0.5
            local latest
            latest=$(ls -t "$RECORDINGS_DIR"/*.mkv 2>/dev/null | head -1)
            if [ -n "$latest" ]; then
                notify-send -a "RegionSelector" -A "open=Open" -A "folder=Folder" "Recording saved" "$latest" --action=open,folder
            else
                notify-send -a "RegionSelector" "Recording saved"
            fi
        fi
        exit 0
    fi

    if [ "$action" = "record" ] && pgrep -x wf-recorder > /dev/null 2>&1; then
        pkill -x wf-recorder
        sleep 0.5
        local latest
        latest=$(ls -t "$RECORDINGS_DIR"/*.mkv 2>/dev/null | head -1)
        if [ -n "$latest" ]; then
            notify-send -a "RegionSelector" -A "open=Open" -A "folder=Folder" "Recording saved" "$latest" --action=open,folder
        else
            notify-send -a "RegionSelector" "Recording saved"
        fi
        exit 0
    fi

    local region
    region=$(select_region)

    case "$action" in
        screenshot) do_screenshot "$region" ;;
        ocr)        do_ocr "$region" ;;
        search)     do_search "$region" ;;
        record)     do_record "$region" ;;
        stop)       ;;
        *)
            echo "Usage: $0 {screenshot|ocr|search|record|stop}" >&2
            exit 1
            ;;
    esac
}

main "$@"
