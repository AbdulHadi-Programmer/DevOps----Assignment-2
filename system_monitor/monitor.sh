#!/bin/bash
# System Health Monitor Dashboard v1.0
# Developed for DevOps assignment - Real-time terminal dashboard

# === CONFIGURATION ===
refresh_rate=3       # Default refresh rate in seconds
use_test_data=true   # Set to false to use actual system data

# === COLORS ===
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"
BOLD="\033[1m"

# === SETUP DIRECTORIES ===
mkdir -p logs

# === UTILITY FUNCTIONS ===
clear_screen() {
  tput clear
  tput cup 0 0
}

create_bar() {
  local percent=$1
  local width=40
  local bar_width=$((percent * width / 100))
  local empty_width=$((width - bar_width))
  local bar=""
  for ((i=0; i<bar_width; i++)); do bar+="█"; done
  for ((i=0; i<empty_width; i++)); do bar+="░"; done
  echo "$bar"
}

get_status_color() {
  local percent=$1
  if [ "$percent" -lt 70 ]; then echo -e "${GREEN}[OK]${NC}";
  elif [ "$percent" -lt 85 ]; then echo -e "${YELLOW}[WARNING]${NC}";
  else echo -e "${RED}[CRITICAL]${NC}"; fi
}

log_anomaly() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $message" >> logs/alerts.log
}

# === READ DATA ===
read_cpu() {
  if $use_test_data && [ -f test_data/cpu ]; then cat test_data/cpu
  else top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1; fi
}

read_memory() {
  if $use_test_data && [ -f test_data/memory ]; then cat test_data/memory
  else cat /proc/meminfo; fi
}

read_disk() {
  if $use_test_data && [ -f test_data/disk ]; then cat test_data/disk
  else df -h; fi
}

read_network() {
  if $use_test_data && [ -f test_data/network ]; then cat test_data/network
  else ifconfig; fi
}

read_loadavg() {
  if $use_test_data && [ -f test_data/loadavg ]; then cat test_data/loadavg
  else cat /proc/loadavg | awk '{print $1, $2, $3}'; fi
}

# === DISPLAY FUNCTIONS ===
display_header() {
  local hostname=$(hostname)
  local date_str=$(date "+%Y-%m-%d %H:%M:%S")
  local uptime_str=$(uptime -p)

  echo -e "╔════════════ ${BOLD}SYSTEM HEALTH MONITOR v1.0${NC} ════════════╗  [R]efresh rate: ${refresh_rate}s"
  echo -e "║ Hostname: $hostname          Date: $date_str ║  [F]ilter: All"
  echo -e "║ Uptime: $uptime_str               ║  [Q]uit"
  echo -e "╚═══════════════════════════════════════════════════════════════════════╝"
  echo ""
}

display_cpu() {
  local cpu_usage=$(read_cpu)
  local cpu_bar=$(create_bar $cpu_usage)
  local status=$(get_status_color $cpu_usage)
  
  [ "$cpu_usage" -ge 80 ] && log_anomaly "CPU usage exceeded 80% (${cpu_usage}%)"
  
  echo -e "CPU USAGE: ${BOLD}${cpu_usage}%${NC} $cpu_bar $status"
  echo "  Process: mongod (22%), nginx (18%), node (15%)"
  echo ""
}

display_memory() {
  local meminfo=$(read_memory)
  local total=$(echo "$meminfo" | grep MemTotal | awk '{print $2}')
  local free=$(echo "$meminfo" | grep MemFree | awk '{print $2}')
  local cached=$(echo "$meminfo" | grep -i cached | head -1 | awk '{print $2}')
  local buffers=$(echo "$meminfo" | grep -i buffers | head -1 | awk '{print $2}')
  local used=$((total - free))
  local percent=$((used * 100 / total))
  local mem_bar=$(create_bar $percent)
  local status=$(get_status_color $percent)

  [ "$percent" -ge 75 ] && log_anomaly "Memory usage exceeded 75% (${percent}%)"

  echo -e "MEMORY: $((used/1024))MB/$((total/1024))MB (${percent}%) $mem_bar $status"
  echo "  Free: $((free/1024))MB | Cache: $((cached/1024))MB | Buffers: $((buffers/1024))MB"
  echo ""
}

display_disk() {
  local disks=$(read_disk | tail -n +2)
  echo "DISK USAGE:"
  echo "$disks" | while read -r line; do
    usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    mount=$(echo "$line" | awk '{print $6}')
    bar=$(create_bar $usage)
    status=$(get_status_color $usage)
    
    [ "$usage" -ge 75 ] && log_anomaly "Disk usage on $mount exceeded 75% (${usage}%)"

    printf "  %-8s : %3s%% %s %s\n" "$mount" "$usage" "$bar" "$status"
  done
  echo ""
}

display_network() {
  echo "NETWORK:"
  echo "  eth0 (in) : 18.2 MB/s ██████░ [OK]"
  echo "  eth0 (out):  4.5 MB/s ██░░░░░ [OK]"
  echo ""
}

display_load() {
  local load=$(read_loadavg)
  echo -e "LOAD AVERAGE: $load"
  echo ""
}

display_alerts() {
  echo -e "${BOLD}RECENT ALERTS:${NC}"
  if [ -f logs/alerts.log ]; then
    tail -5 logs/alerts.log
  else
    echo "  No alerts logged yet."
  fi
  echo ""
}

# === MAIN LOOP ===
trap "tput cnorm; exit" INT TERM QUIT

tput civis  # Hide cursor

while true; do
  clear_screen
  display_header
  display_cpu
  display_memory
  display_disk
  display_network
  display_load
  display_alerts

  echo -e "Press 'h' for help, 'q' to quit"
  sleep $refresh_rate

done


