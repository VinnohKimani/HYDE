#!/usr/bin/env bash
# ==============================================================================
# Battery Warning Daemon for Apple MacBook Pro
# Emits Dunst desktop alerts for low (<20%), critical (<10%), and emergency (<5%)
# ==============================================================================
set -euo pipefail

STATE_FILE="/tmp/battery_monitor_state"

get_battery_info() {
    local bat_path=""
    for b in /sys/class/power_supply/BAT*; do
        if [[ -d "$b" ]]; then
            bat_path="$b"
            break
        fi
    done

    if [[ -z "$bat_path" ]]; then
        echo "0:Unknown"
        return
    fi

    local capacity
    local status
    capacity=$(cat "${bat_path}/capacity" 2>/dev/null || echo "100")
    status=$(cat "${bat_path}/status" 2>/dev/null || echo "Unknown")

    echo "${capacity}:${status}"
}

check_battery() {
    local info
    info=$(get_battery_info)
    local capacity="${info%%:*}"
    local status="${info##*:}"

    # If charging or full, clear state file and exit
    if [[ "$status" == "Charging" ]] || [[ "$status" == "Full" ]]; then
        rm -f "$STATE_FILE"
        return
    fi

    # Read previous notified level
    local last_state="normal"
    if [[ -f "$STATE_FILE" ]]; then
        last_state=$(cat "$STATE_FILE")
    fi

    if [[ "$capacity" -le 5 ]] && [[ "$last_state" != "emergency" ]]; then
        dunstify -u critical -i "battery-empty" -r 9999 "BATTERY CRITICAL (5%)" "Connect charger immediately! System will hibernate/shutdown soon."
        echo "emergency" > "$STATE_FILE"
    elif [[ "$capacity" -le 10 ]] && [[ "$capacity" -gt 5 ]] && [[ "$last_state" != "critical" ]] && [[ "$last_state" != "emergency" ]]; then
        dunstify -u critical -i "battery-caution" -r 9999 "Battery Low (10%)" "Please plug in your MagSafe adapter."
        echo "critical" > "$STATE_FILE"
    elif [[ "$capacity" -le 20 ]] && [[ "$capacity" -gt 10 ]] && [[ "$last_state" == "normal" ]]; then
        dunstify -u normal -i "battery-low" -r 9999 "Battery Notice (20%)" "Battery is running low."
        echo "low" > "$STATE_FILE"
    fi
}

# Run check once (or loop if passed --daemon)
if [[ "${1:-}" == "--daemon" ]]; then
    while true; do
        check_battery
        sleep 60
    done
else
    check_battery
fi
