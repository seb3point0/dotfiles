# shellcheck shell=bash
# External IP address, cached for 5 minutes
source ~/.dotfiles/oh-my-posh/palette.sh

run_segment() {
	local cache="/tmp/.tmux_ext_ip"
	local max_age=300

	if [[ -f "$cache" ]]; then
		if [[ "$(uname -s)" == "Darwin" ]]; then
			local age=$(( $(date +%s) - $(stat -f %m "$cache") ))
		else
			local age=$(( $(date +%s) - $(stat -c %Y "$cache") ))
		fi
		if [[ $age -lt $max_age ]]; then
			echo "#[fg=${NORD8}]󰈀 #[fg=${NORD6}]$(cat "$cache")"
			return 0
		fi
	fi

	local ip
	ip=$(curl -4 -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "?")
	echo "$ip" > "$cache"
	echo "#[fg=${NORD8}]󰈀 #[fg=${NORD6}]$ip"
	return 0
}
