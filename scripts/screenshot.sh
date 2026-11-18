#!/usr/bin/env bash
# ==============================================================================
# Direct High-Resolution Wayland Screenshot Utility
# Supports grim, slurp, swappy, and wl-clipboard
# ==============================================================================
set -euo pipefail

SAVE_DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TARGET_FILE="${SAVE_DIR}/Screenshot_${TIMESTAMP}.png"

MODE="${1:-area}"
EDIT="${2:-}"

notify_screenshot() {
    local file="$1"
    dunstify -a "screenshot" -i "$file" -u low "Screenshot Captured" "Saved to ${file}\nCopied to clipboard."
}

case "$MODE" in
    full)
        grim "$TARGET_FILE"
        wl-copy < "$TARGET_FILE"
        notify_screenshot "$TARGET_FILE"
        ;;
    area)
        GEOM=$(slurp -d -b 00000088 -c 89b4faff -w 2 || true)
        if [[ -z "$GEOM" ]]; then
            exit 0 # User cancelled selection
        fi
        grim -g "$GEOM" "$TARGET_FILE"
        wl-copy < "$TARGET_FILE"
        notify_screenshot "$TARGET_FILE"
        ;;
    window)
        # Capture focused Hyprland window
        ACTIVE_WIN=$(hyprctl activewindow -j)
        X=$(echo "$ACTIVE_WIN" | jq -r '.at[0]')
        Y=$(echo "$ACTIVE_WIN" | jq -r '.at[1]')
        W=$(echo "$ACTIVE_WIN" | jq -r '.size[0]')
        H=$(echo "$ACTIVE_WIN" | jq -r '.size[1]')
        GEOM="${X},${Y} ${W}x${H}"
        grim -g "$GEOM" "$TARGET_FILE"
        wl-copy < "$TARGET_FILE"
        notify_screenshot "$TARGET_FILE"
        ;;
    *)
        echo "Usage: $(basename "$0") [full|area|window] [--edit]" >&2
        exit 1
        ;;
esac

if [[ "$EDIT" == "--edit" ]] && command -v swappy >/dev/null 2>&1; then
    swappy -f "$TARGET_FILE"
fi
