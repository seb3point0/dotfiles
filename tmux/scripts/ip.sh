#!/bin/bash
# Returns the external (public) IP address, cached for 5 minutes.
# Cross-platform: macOS and Linux.

CACHE="/tmp/.tmux_ext_ip"
MAX_AGE=300  # seconds

if [[ -f "$CACHE" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
        age=$(( $(date +%s) - $(stat -f %m "$CACHE") ))
    else
        age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
    fi
    if [[ $age -lt $MAX_AGE ]]; then
        cat "$CACHE"
        exit 0
    fi
fi

ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "?")
echo "$ip" > "$CACHE"
echo "$ip"
