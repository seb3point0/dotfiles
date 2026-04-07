# shellcheck shell=bash
# User@hostname with nerd font icon
source ~/.dotfiles/oh-my-posh/palette.sh

run_segment() {
	echo "#[fg=${NORD8}]󰀇 #[fg=${NORD6}]$(whoami)@$(hostname -s)"
	return 0
}
