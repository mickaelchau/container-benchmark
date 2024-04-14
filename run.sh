#!/bin/bash

# Change the container functions to the one you want to test
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$DIR/containers_functions/docker.sh"

# Define a trap function
trap cleanup SIGINT
trap "error $LINENO" ERR

error() {
  echo "Error: $1"
  cleanup
  exit 1
}
# The command to execute on script end or Ctrl + C
cleanup() {
  rm -f image.tar || echo "No file, skipping"
  rm -f image.tar.gz || echo "No file, skipping"
  stop_command || echo "No container, skipping"
  remove_container_command || echo "No container, skipping"
  remove_image_command || echo "No Image, skipping"
  exit 0
}

function get_date_time() {
  local date_time
  date_time=$(date "+%Y-%m-%d %H:%M:%S")
  echo "$date_time"
}

function progress {
  clear
  local _done _left _fill _empty _progress current
  current=$(($1))
  _progress=$((($current * 10000 / $2) / 100))
  _done=$(($_progress * 6 / 10))
  _left=$((60 - $_done))
  _fill=$(printf "%${_done}s")
  _empty=$(printf "%${_left}s")
  local NC='\033[0m'
  printf "\r$current / $2 : [${NC}${_fill// /#}${_empty// /-}] ${_progress}%%${NC}"
}

# Function used to get the time execution of a function
function get_command_time() {
  #echo "hi bro\n"
  local start end total
  start=$(date +%s%N)
  #echo "hi bro22\n"
  #echo $start
  "$1" >> /dev/null  
  #echo "hi bro33\n"
  end=$(date +%s%N)

  total=$((end - start))
  #echo "hi bro44\n"
  echo $total
}

# NEWWWW

# Function to get the time execution of a function and monitor system resources
function get_command_time_and_monitor_resources() {
  local start end total command iteration uid
  command="$1"
  iteration="$2"
  uid=$(date +%Y%m%d%H%M%S%N)  # Unique identifier based on timestamp

  # Start resource monitoring in the background with unique identifier
  start_resource_monitoring "$command" "$iteration" "$uid" &

  local monitoring_pid=$!
  start=$(date +%s%N)
  "$command" >/dev/null
  end=$(date +%s%N)
  total=$((end - start))

  # Stop the resource monitoring
  kill $monitoring_pid

  echo $total
}

# Function to start resource monitoring
function start_resource_monitoring() {
  local command="$1"
  local iteration="$2"
  local uid="$3"
  local date_time interval=1  # interval in seconds for monitoring

  while true; do
    date_time=$(date +%Y-%m-%d_%H-%M-%S)

    # Log CPU, Disk, and Memory usage
    local log_entry="$uid;$iteration;$command;$date_time"
    log_cpu_usage "$log_entry"
    log_disk_usage "$log_entry"
    log_memory_usage "$log_entry"

    sleep $interval
  done
}

function log_cpu_usage() {
  local log_entry="$1"
  local cpu=$(mpstat 1 1 | grep Average)
  local usr=$(echo $cpu | awk '{print $3}')
  local nice=$(echo $cpu | awk '{print $4}')
  local sys=$(echo $cpu | awk '{print $5}')
  local iowait=$(echo $cpu | awk '{print $6}')
  local soft=$(echo $cpu | awk '{print $8}')
  echo "$log_entry;cpu;$usr;$nice;$sys;$iowait;$soft" >> logs/machine_monitoring.csv
}

function log_disk_usage() {
  local log_entry="$1"
  local disk=$(df | grep '/$')
  local used=$(echo $disk | awk '{print $3}')
  echo "$log_entry;disk;$used" >> logs/machine_monitoring.csv
}

function log_memory_usage() {
  local log_entry="$1"
  local mem=$(free | grep Mem)
  local used_mem=$(echo $mem | awk '{print $3}')
  local cached=$(cat /proc/meminfo | grep -i Cached | sed -n '1p' | awk '{print $2}')
  local buffer=$(cat /proc/meminfo | grep -i Buffers | awk '{print $2}')
  local swap=$(cat /proc/meminfo | grep -i Swap | grep -i Free | awk '{print $2}')
  echo "$log_entry;mem;$used_mem;$cached;$buffer;$swap" >> logs/machine_monitoring.csv
}

count=0
max_runs=100
export image_name="hpl"
while [[ $count -lt $max_runs ]]; do
   
    load_time=$(get_command_time_and_monitor_resources "load_command" "$count")
    instantiate_time=$(get_command_time_and_monitor_resources "start_command" "$count")
    #sleep 30
    stop_time=$(get_command_time_and_monitor_resources "stop_command" "$count")
    container_removal_time=$(get_command_time_and_monitor_resources "remove_container_command" "$count")
    image_removal_time=$(get_command_time_and_monitor_resources "remove_image_command" "$count")
    #sleep 60
    display_date=$(get_date_time)

    echo "$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" >>"logs/dockertest"
    echo "$count;$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" 
    count=$((count + 1))
done


printf "\n"
