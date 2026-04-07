# shellcheck shell=bash
# RAM usage with nerd font icon
source ~/.dotfiles/oh-my-posh/palette.sh

run_segment() {
	local ram
	local raw
	if [[ "$(uname -s)" == "Linux" ]]; then
		raw=$(free -m | awk 'NR==2{printf "%.4f", $3/1024}')
	else
		raw=$(vm_stat | awk '
			/page size of/ { size = $8 }
			/Pages active/  { gsub(/\./, "", $3); active = $3 }
			/Pages wired down/ { gsub(/\./, "", $4); wired = $4 }
			END { printf "%.4f", (active + wired) * size / 1073741824 }
		')
	fi
	local ram
	ram=$(awk -v v="$raw" 'BEGIN { r=sprintf("%.2f",v); if (r+0 >= 10) printf "%.1fG", v; else printf "%.2fG", v }')
	echo "#[fg=${NORD8}]󰍛 #[fg=${NORD6}]${ram}"
	return 0
}
