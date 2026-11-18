#!/usr/bin/env bash
# ==============================================================================
# Audio Volume Controller with Intelligent Auto-Unmute & Dunst Feedback
# Supports PipeWire (wpctl) with fallback to pamixer
# ==============================================================================
set -euo pipefail

ACTION="${1:-get}"
STEP="${2:-5%}"

get_volume() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
    elif command -v pamixer >/dev/null 2>&1; then
        pamixer --get-volume
    else
        echo "0"
    fi
}

is_muted() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"
    elif command -v pamixer >/dev/null 2>&1; then
        pamixer --get-mute
    else
        return 1
    fi
}

notify_volume() {
    local vol
    vol="$(get_volume)"
    local icon="audio-volume-high-symbolic"

    if is_muted; then
        dunstify -a "volume" -u low -r 9991 -i "audio-volume-muted-symbolic" "Volume: Muted"
        return
    fi

    if [[ "$vol" -eq 0 ]]; then
        icon="audio-volume-muted-symbolic"
    elif [[ "$vol" -lt 30 ]]; then
        icon="audio-volume-low-symbolic"
    elif [[ "$vol" -lt 70 ]]; then
        icon="audio-volume-medium-symbolic"
    else
        icon="audio-volume-high-symbolic"
    fi

    dunstify -a "volume" -u low -r 9991 -h "int:value:${vol}" -i "$icon" "Volume: ${vol}%"
}

case "$ACTION" in
    up)
        # Auto-unmute when raising volume
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
        elif command -v pamixer >/dev/null 2>&1; then
            pamixer -u
            pamixer -i 5 --allow-boost --max-volume 150
        fi
        notify_volume
        ;;
    down)
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        elif command -v pamixer >/dev/null 2>&1; then
            pamixer -u
            pamixer -d 5
        fi
        notify_volume
        ;;
    mute)
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        elif command -v pamixer >/dev/null 2>&1; then
            pamixer -t
        fi
        notify_volume
        ;;
    mic-mute)
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        elif command -v pamixer >/dev/null 2>&1; then
            pamixer --default-source -t
        fi
        dunstify -a "microphone" -u low -r 9992 -i "audio-input-microphone-symbolic" "Microphone Toggled"
        ;;
    get)
        get_volume
        ;;
    *)
        echo "Usage: $(basename "$0") [up|down|mute|mic-mute|get]" >&2
        exit 1
        ;;
esac
