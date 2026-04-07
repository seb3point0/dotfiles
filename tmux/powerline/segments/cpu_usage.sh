# shellcheck shell=bash
# CPU load average with nerd font icon
source ~/.dotfiles/oh-my-posh/palette.sh

run_segment() {
	local cpu
	local raw
	if [[ "$(uname -s)" == "Linux" ]]; then
		raw=$(awk '{print $1}' /proc/loadavg)
	else
		raw=$(sysctl -n vm.loadavg | awk '{print $2}')
	fi
	local cpu
	cpu=$(awk -v v="$raw" 'BEGIN { r=sprintf("%.2f",v); if (r+0 >= 10) printf "%.1f", v; else printf "%.2f", v }')

	echo "#[fg=${NORD8}]󰘚 #[fg=${NORD6}]${cpu}"
	return 0
}
