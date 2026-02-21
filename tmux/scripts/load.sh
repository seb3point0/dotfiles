#!/bin/bash
cpu=$(sysctl -n vm.loadavg | awk '{print $2}')
ram=$(vm_stat | awk '
  /page size of/ { size = $8 }
  /Pages active/  { gsub(/\./, "", $3); active = $3 }
  /Pages wired down/ { gsub(/\./, "", $4); wired = $4 }
  END { printf "%.1fG", (active + wired) * size / 1073741824 }
')
echo "󰘚 ${cpu}  󰍛 ${ram}"
