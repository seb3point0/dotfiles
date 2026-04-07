# shellcheck shell=bash
# Nord Theme for tmux-powerline
# Colors sourced from shared palette
source ~/.dotfiles/oh-my-posh/palette.sh

# No separators — just spacing
TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=" "
TMUX_POWERLINE_SEPARATOR_LEFT_THIN=" "
TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=" "
TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=" "

# Solid background across the entire status bar
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-${NORD1}}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-${NORD4}}
# shellcheck disable=SC2034
TMUX_POWERLINE_SEG_AIR_COLOR=$(tp_air_color)

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}

# Current (active) window: highlighted number + name
# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_CURRENT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
		"#[fg=${NORD0},bg=${NORD8}] #I"
		"#[fg=${NORD0},bg=${NORD8}] #W "
		"#[$(tp_format regular)]"
		" "
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_STYLE" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_STYLE=(
		"$(tp_format regular)"
	)
fi

# Inactive windows: dimmed number + name on the status bar bg
# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_FORMAT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
		"#[fg=${NORD4},bg=${NORD1}] #I"
		"#[fg=${NORD4},bg=${NORD1}] #W "
		" "
	)
fi

# Format: segment_name background foreground [separator] [sep_bg] [sep_fg] [spacing] [separator_disable]

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_LEFT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
		"session_prefix ${NORD1} ${NORD6} default_separator no_sep_bg_color no_sep_fg_color both_disable separator_disable"
		"vcs_branch ${NORD1} ${NORD14}"
	)
fi

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		"tailscale ${NORD1} ${NORD9} default_separator ${NORD0} no_sep_fg_color"
		"user_host ${NORD1} ${NORD4} default_separator ${NORD0} no_sep_fg_color"
		"ext_ip ${NORD1} ${NORD8} default_separator ${NORD0} no_sep_fg_color"
		"cpu_usage ${NORD1} ${NORD13} default_separator ${NORD0} no_sep_fg_color"
		"ram_usage ${NORD1} ${NORD13} default_separator ${NORD0} no_sep_fg_color"
		"battery_nord ${NORD1} ${NORD6} default_separator ${NORD0} no_sep_fg_color"
		"time_nord ${NORD1} ${NORD6} default_separator ${NORD0} no_sep_fg_color right_disable"
	)
fi
