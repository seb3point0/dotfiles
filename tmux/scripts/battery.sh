#!/bin/bash
batt_info=$(pmset -g batt 2>/dev/null)

# Only show on laptops (where internal battery exists)
if ! echo "$batt_info" | grep -q "InternalBattery"; then
  exit 0
fi

percentage=$(echo "$batt_info" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
[ -z "$percentage" ] && exit 0

if echo "$batt_info" | grep -qE "charging|charged"; then
  icon="󰂄"
elif [ "$percentage" -ge 90 ]; then icon="󰁹"
elif [ "$percentage" -ge 70 ]; then icon="󰂂"
elif [ "$percentage" -ge 50 ]; then icon="󰂀"
elif [ "$percentage" -ge 30 ]; then icon="󰁾"
elif [ "$percentage" -ge 10 ]; then icon="󰁼"
else icon="󰁺"
fi

echo "${icon} ${percentage}%"
