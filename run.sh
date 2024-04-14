#!/bin/bash

# Change the container functions to the one you want to test
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
service="$1"
time_log_path="logs/${service}_time.csv"
machine_resources_log_path="logs/${service}_machine_resources.csv"
source "$DIR/containers_functions/${service}.sh"

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


# Function to get the time execution of a function and monitor system resources
function get_command_time_and_monitor_resources() {
  local start end total command concurrency count
  command="$1"
  concurrency="$2"
  count="$3"

  # Start resource monitoring in the background with unique identifier
  start_resource_monitoring "$command" "$concurrency" "$count" &

  local monitoring_pid=$!
  start=$(date +%s%N)
  "$command" "$concurrency" >/dev/null
  end=$(date +%s%N)
  total=$((end - start))

  # Stop the resource monitoring
  kill $monitoring_pid

  echo $total
}

# Function to start resource monitoring
function start_resource_monitoring() {
  local command="$1"
  local concurrency="$2"
  local count="$3"
  local date_time interval=1  # interval in seconds for monitoring

  while true; do
    date_time=$(date +%Y-%m-%d_%H-%M-%S)

    # Log CPU, Disk, and Memory usage
    local log_entry="$concurrency;$count;$command;$date_time"
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
  echo "$log_entry;cpu;$usr;$nice;$sys;$iowait;$soft" >> "$machine_resources_log_path"
}

function log_disk_usage() {
  local log_entry="$1"
  local disk=$(df | grep '/$')
  local used=$(echo $disk | awk '{print $3}')
  echo "$log_entry;disk;$used" >> "$machine_resources_log_path"
}

function log_memory_usage() {
  local log_entry="$1"
  local mem=$(free | grep Mem)
  local used_mem=$(echo $mem | awk '{print $3}')
  local cached=$(cat /proc/meminfo | grep -i Cached | sed -n '1p' | awk '{print $2}')
  local buffer=$(cat /proc/meminfo | grep -i Buffers | awk '{print $2}')
  local swap=$(cat /proc/meminfo | grep -i Swap | grep -i Free | awk '{print $2}')
  echo "$log_entry;mem;$used_mem;$cached;$buffer;$swap" >> "$machine_resources_log_path"
}

max_runs=2
export image_name="hpl"

for concurrency in 1 2 4 8; do
  count=1
  while [[ $count -le $max_runs ]]; do
   
    load_time=$(get_command_time_and_monitor_resources "load_command" "$concurrency" "$count")
    instantiate_time=$(get_command_time_and_monitor_resources "start_command" "$concurrency" "$count")
    sudo docker container ls
    #start_command 5 
    #sleep 30
    stop_time=$(get_command_time_and_monitor_resources "stop_command" "$concurrency" "$count")
    container_removal_time=$(get_command_time_and_monitor_resources "remove_container_command" "$concurrency" "$count")
    image_removal_time=$(get_command_time_and_monitor_resources "remove_image_command" "$concurrency" "$count")
    #sleep 60
    display_date=$(get_date_time)

    echo "$concurrency;$count;$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" >>"$time_log_path"
    echo "$concurrency;$count;$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" 
    count=$((count + 1))
  done
done


printf "\n"
