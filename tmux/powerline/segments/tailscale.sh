# shellcheck shell=bash
# Tailscale status — shows "TS" when connected (detects 100.x.x.x CGNAT address)
source ~/.dotfiles/oh-my-posh/palette.sh

run_segment() {
	if ifconfig 2>/dev/null | grep -q 'inet 100\.' || \
	   ip addr   2>/dev/null | grep -q 'inet 100\.'; then
		echo "#[fg=${NORD8}]󰖂 #[fg=${NORD6}]TS"
	fi
	return 0
}
