#!/usr/bin/env bash
# ==============================================================================
# Smooth Brightness Control for Display & Apple Keyboard Backlight
# Supports MacBook Pro 12,1 screen (intel_backlight) and keyboard (smc::kbd_backlight)
# ==============================================================================
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [screen|kbd] [up|down|get|set <val>]
Examples:
  $(basename "$0") screen up       # Increase screen brightness by 5%
  $(basename "$0") screen down     # Decrease screen brightness by 5%
  $(basename "$0") kbd up          # Increase keyboard backlight
  $(basename "$0") kbd down        # Decrease keyboard backlight
EOF
    exit 1
}

TARGET="${1:-screen}"
ACTION="${2:-get}"
VALUE="${3:-5%}"

notify_brightness() {
    local percent="$1"
    local icon="display-brightness-symbolic"
    dunstify -a "brightness" -u low -r 9993 -h "int:value:${percent}" -i "$icon" "Brightness: ${percent}%"
}

notify_kbd() {
    local percent="$1"
    local icon="keyboard-brightness-symbolic"
    dunstify -a "kbd_brightness" -u low -r 9994 -h "int:value:${percent}" -i "$icon" "Keyboard Light: ${percent}%"
}

case "$TARGET" in
    screen|display)
        case "$ACTION" in
            up)
                brightnessctl -q set +5%
                notify_brightness "$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
                ;;
            down)
                brightnessctl -q -n 2 set 5%-
                notify_brightness "$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
                ;;
            set)
                brightnessctl -q set "$VALUE"
                notify_brightness "$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
                ;;
            get)
                brightnessctl -m | cut -d, -f4
                ;;
            *)
                usage
                ;;
        esac
        ;;
    kbd|keyboard)
        # Check for Apple keyboard backlight device
        KBD_DEV=""
        for dev in $(brightnessctl --list | grep "kbd_backlight" | cut -d"'" -f2); do
            KBD_DEV="$dev"
            break
        done

        if [[ -z "$KBD_DEV" ]]; then
            echo "No keyboard backlight device detected." >&2
            exit 1
        fi

        case "$ACTION" in
            up)
                brightnessctl -d "$KBD_DEV" -q set +10%
                notify_kbd "$(brightnessctl -d "$KBD_DEV" -m | cut -d, -f4 | tr -d '%')"
                ;;
            down)
                brightnessctl -d "$KBD_DEV" -q set 10%-
                notify_kbd "$(brightnessctl -d "$KBD_DEV" -m | cut -d, -f4 | tr -d '%')"
                ;;
            get)
                brightnessctl -d "$KBD_DEV" -m | cut -d, -f4
                ;;
            *)
                usage
                ;;
        esac
        ;;
    *)
        usage
        ;;
esac
