#!/bin/bash
if [[ "$(uname -s)" == "Linux" ]]; then
    cpu=$(awk '{print $1}' /proc/loadavg)
    ram=$(free -m | awk 'NR==2{printf "%.1fG", $3/1024}')
else
    cpu=$(sysctl -n vm.loadavg | awk '{print $2}')
    ram=$(vm_stat | awk '
      /page size of/ { size = $8 }
      /Pages active/  { gsub(/\./, "", $3); active = $3 }
      /Pages wired down/ { gsub(/\./, "", $4); wired = $4 }
      END { printf "%.1fG", (active + wired) * size / 1073741824 }
    ')
fi
echo "󰘚 ${cpu}  󰍛 ${ram}"
