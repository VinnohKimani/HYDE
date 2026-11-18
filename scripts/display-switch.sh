#!/usr/bin/env bash
# ==============================================================================
# Display Profile Switcher for Hyprland on MacBook Pro 12,1
# Easily toggle between Retina internal (eDP-1), HDMI-A-1, and DP-1
# ==============================================================================
set -euo pipefail

INTERNAL="eDP-1"
RETINA_RES="2560x1600@60"
RETINA_SCALE="2" # Crisp 2x HiDPI Retina scale (effective 1280x800 desktop space)

# Detect external display (HDMI or Mini-DisplayPort/Thunderbolt)
EXTERNAL=$(hyprctl monitors all -j | jq -r '.[].name' | grep -v "^${INTERNAL}$" | head -n1 || true)

usage() {
    cat <<EOF
Usage: $(basename "$0") [laptop|extend|mirror|external|auto]
Modes:
  laptop    - Enable internal display only (disable external)
  extend    - Extend desktop to external monitor (internal left, external right)
  mirror    - Duplicate internal display onto external monitor
  external  - Enable external display only (clamshell mode)
  auto      - Auto-detect and configure based on connected monitors
EOF
    exit 1
}

MODE="${1:-auto}"

if [[ -z "$EXTERNAL" ]] && [[ "$MODE" != "laptop" ]] && [[ "$MODE" != "auto" ]]; then
    dunstify -a "display" -u normal "Display Switch" "No external display detected."
    exit 0
fi

case "$MODE" in
    laptop)
        hyprctl keyword monitor "${INTERNAL},${RETINA_RES},0x0,${RETINA_SCALE}"
        if [[ -n "$EXTERNAL" ]]; then
            hyprctl keyword monitor "${EXTERNAL},disable"
        fi
        dunstify -a "display" -u low "Display Mode" "Internal Retina Display Only"
        ;;
    extend)
        # Position internal at 0x0, external at right (e.g. 1280x0)
        hyprctl keyword monitor "${INTERNAL},${RETINA_RES},0x0,${RETINA_SCALE}"
        hyprctl keyword monitor "${EXTERNAL},preferred,1280x0,1"
        dunstify -a "display" -u low "Display Mode" "Extended Desktop (${INTERNAL} + ${EXTERNAL})"
        ;;
    mirror)
        hyprctl keyword monitor "${INTERNAL},${RETINA_RES},0x0,${RETINA_SCALE}"
        hyprctl keyword monitor "${EXTERNAL},preferred,0x0,1,mirror,${INTERNAL}"
        dunstify -a "display" -u low "Display Mode" "Mirrored Display (${EXTERNAL})"
        ;;
    external)
        if [[ -n "$EXTERNAL" ]]; then
            hyprctl keyword monitor "${INTERNAL},disable"
            hyprctl keyword monitor "${EXTERNAL},preferred,0x0,1"
            dunstify -a "display" -u low "Display Mode" "External Monitor Only (Clamshell)"
        fi
        ;;
    auto)
        if [[ -n "$EXTERNAL" ]]; then
            hyprctl keyword monitor "${INTERNAL},${RETINA_RES},0x0,${RETINA_SCALE}"
            hyprctl keyword monitor "${EXTERNAL},preferred,1280x0,1"
            dunstify -a "display" -u low "Display Mode" "Auto: Extended to ${EXTERNAL}"
        else
            hyprctl keyword monitor "${INTERNAL},${RETINA_RES},0x0,${RETINA_SCALE}"
            dunstify -a "display" -u low "Display Mode" "Auto: Retina Screen Active"
        fi
        ;;
    *)
        usage
        ;;
esac
