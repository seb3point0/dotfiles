#!/bin/bash
# Detect Tailscale connection by presence of a 100.x.x.x CGNAT address.
# Works on macOS (ifconfig) and Linux (ip addr), no CLI path dependency.

if ifconfig 2>/dev/null | grep -q 'inet 100\.' || \
   ip addr   2>/dev/null | grep -q 'inet 100\.'; then
    SEP=$'\xee\x82\xb2'
    printf "#[fg=colour110,bg=colour237]%s#[fg=colour237,bg=colour110,bold] TS #[nobold,fg=colour237,bg=colour110]%s" "$SEP" "$SEP"
fi
