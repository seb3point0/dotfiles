#!/bin/bash
# Outputs a full tmux-formatted battery block (with separators) when a battery
# is present, and nothing when running on a non-laptop (desktop/server).
# Cross-platform: macOS (pmset) and Linux (/sys/class/power_supply).

SEP=$'\xee\x82\xb2'

get_icon() {
    local pct="$1" status="$2"
    if [[ "$status" == "Charging" || "$status" == "Full" || "$status" == "charged" || "$status" == "charging" ]]; then
        echo "󰂄"
    elif [[ "$pct" -ge 90 ]]; then echo "󰁹"
    elif [[ "$pct" -ge 70 ]]; then echo "󰂂"
    elif [[ "$pct" -ge 50 ]]; then echo "󰂀"
    elif [[ "$pct" -ge 30 ]]; then echo "󰁾"
    elif [[ "$pct" -ge 10 ]]; then echo "󰁼"
    else echo "󰁺"
    fi
}

if [[ "$(uname -s)" == "Linux" ]]; then
    bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
    [[ -z "$bat_dir" ]] && exit 0

    pct=$(cat "$bat_dir/capacity" 2>/dev/null)
    [[ -z "$pct" ]] && exit 0

    status=$(cat "$bat_dir/status" 2>/dev/null)
    icon=$(get_icon "$pct" "$status")
else
    batt_info=$(pmset -g batt 2>/dev/null)
    echo "$batt_info" | grep -q "InternalBattery" || exit 0

    pct=$(echo "$batt_info" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
    [[ -z "$pct" ]] && exit 0

    status=$(echo "$batt_info" | grep -Eo 'charging|charged|discharging' | head -1)
    icon=$(get_icon "$pct" "$status")
fi

printf "#[fg=colour239,bg=colour237]%s#[fg=colour223,bg=colour239] %s %s%% #[fg=colour237,bg=colour239]%s" \
    "$SEP" "$icon" "$pct" "$SEP"
