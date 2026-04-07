# shellcheck shell=bash
# Time with colored icon
source ~/.dotfiles/oh-my-posh/palette.sh

run_segment() {
	echo "#[fg=${NORD8}]󰥔 #[fg=${NORD6}]$(date +%H:%M) "
	return 0
}
