# shellcheck shell=bash
# Battery with colored icon
source ~/.dotfiles/oh-my-posh/palette.sh

run_segment() {
	local icon pct batt_state

	if [[ "$(uname -s)" == "Linux" ]]; then
		local bat_dir
		bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
		[[ -z "$bat_dir" ]] && return 1
		pct=$(cat "$bat_dir/capacity" 2>/dev/null)
		[[ -z "$pct" ]] && return 1
		batt_state=$(cat "$bat_dir/status" 2>/dev/null)
	else
		local batt_info
		batt_info=$(pmset -g batt 2>/dev/null)
		echo "$batt_info" | grep -q "InternalBattery" || return 1
		pct=$(echo "$batt_info" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
		[[ -z "$pct" ]] && return 1
		batt_state=$(echo "$batt_info" | grep -Eo 'charging|charged|discharging' | head -1)
	fi

	if [[ "$batt_state" == "charging" || "$batt_state" == "Charging" || "$batt_state" == "charged" || "$batt_state" == "Full" ]]; then
		icon="󰂄"
	elif [[ "$pct" -ge 80 ]]; then icon="󰁹"
	elif [[ "$pct" -ge 60 ]]; then icon="󰁾"
	elif [[ "$pct" -ge 40 ]]; then icon="󰁼"
	elif [[ "$pct" -ge 20 ]]; then icon="󰁻"
	else icon="󰁺"
	fi

	echo "#[fg=${NORD8}]${icon} #[fg=${NORD6}]${pct}%"
	return 0
}
