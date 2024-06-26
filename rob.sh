#!/bin/bash

# Change the container functions to the one you want to test
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
service="$1"
time_log_path="logs/${service}_time.csv"
machine_resources_log_name="${service}_machine_resources.csv"
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
  # start_resource_monitoring "$command" "$concurrency" "$count" &
  local log_file_prefix="logs/${command}_${concurrency}_${count}"
  local date_time interval=0.01  # interval in seconds for monitoring
  collectl -D -scdm -i $interval -P -f "$log_file_prefix" --hr 0 -oz
  local monitoring_pid=$(pgrep -f "collectl -D -scdm -i $interval -P -f $log_file_prefix --hr 0 -oz")

  start=$(date +%s%N)
  # "$command" "$concurrency" >/dev/null
  end=$(date +%s%N)
  total=$((end - start))

  echo "Monitoring"
  # Stop the resource monitoring
  kill $monitoring_pid

  # Process monitoring output.
  # process_collectl_output "$log_file_prefix" "$command" "$concurrency" "$count"

  # Clean up temporary collectl output file
  # rm -f "$log_file_prefix"

  echo $total
}

# Function to start resource monitoring
function start_resource_monitoring() {
  local command="$1"
  local concurrency="$2"
  local count="$3"
  local date_time interval=0.01  # interval in seconds for monitoring
  local log_file_prefix="logs/${command}_${concurrency}_${count}"

  # Start collectl in the background, saving output to a temporary file
  collectl -scdm -i $interval -P -f "$log_file_prefix" --hr 0 -oz
  # collectl -scdm -i $interval -P -f "$log_file_prefix" --hr 0 -oz &
  local collectl_pid=$!

  # Wait for the command to finish
  # wait $!

  # Stop collectl
  # kill $collectl_pid

  # Process collectl output and extract relevant data
  process_collectl_output "$log_file_prefix" "$command" "$concurrency" "$count"

  # Clean up temporary collectl output file
  rm -f "$log_file_prefix"
}

function process_collectl_output() {
  local log_file_prefix="$(ls $1*)"
  local command="$2"
  local concurrency="$3"
  local count="$4"
  local date_time

  # Extract CPU data
  grep -E '^Date\|[0-9]+\.[0-9]+\s+cpu' "$log_file_prefix" | while read -r line; do
    if [[ "$line" =~ ^Date ]]; then
      date_time=$(echo "$line" | awk '{print $2 " " $3}')
    else
      cpu_user=$(echo "$line" | awk '{print $3}')
      cpu_sys=$(echo "$line" | awk '{print $5}')
      cpu_wait=$(echo "$line" | awk '{print $6}')
      echo "$concurrency;$count;$command;$date_time;$cpu_user;$cpu_sys;$cpu_wait" >> "logs/cpu_${machine_resources_log_name}"
    fi
  done

  # Extract disk data (assuming sda as the main disk)
  grep -E '^Date\|[0-9]+\.[0-9]+\s+sda' "$log_file_prefix" | while read -r line; do
    if [[ "$line" =~ ^Date ]]; then
      date_time=$(echo "$line" | awk '{print $2 " " $3}')
    else
      disk_read=$(echo "$line" | awk '{print $5}')
      disk_write=$(echo "$line" | awk '{print $6}')
      echo "$concurrency;$count;$command;$date_time;$disk_read;$disk_write" >> "logs/disk_${machine_resources_log_name}"
    fi
  done

  # Extract memory data
  grep -E '^Date\|[0-9]+\.[0-9]+\s+Mem' "$log_file_prefix" | while read -r line; do
    if [[ "$line" =~ ^Date ]]; then
      date_time=$(echo "$line" | awk '{print $2 " " $3}')
    else
      mem_used=$(echo "$line" | awk '{print $3}')
      mem_free=$(echo "$line" | awk '{print $5}')
      echo "$concurrency;$count;$command;$date_time;$mem_used;$mem_free" >> "logs/memory_${machine_resources_log_name}"
    fi
  done
}

max_runs=100
export image_name="hpl"

for concurrency in 1 2 4 8; do
  count=1
  while [[ $count -le $max_runs ]]; do
   
    load_time=$(get_command_time_and_monitor_resources "load_command" "$concurrency" "$count")
    instantiate_time=$(get_command_time_and_monitor_resources "start_command" "$concurrency" "$count")
    sleep 30
    stop_time=$(get_command_time_and_monitor_resources "stop_command" "$concurrency" "$count")
    container_removal_time=$(get_command_time_and_monitor_resources "remove_container_command" "$concurrency" "$count")
    image_removal_time=$(get_command_time_and_monitor_resources "remove_image_command" "$concurrency" "$count")
    sleep 60
    display_date=$(get_date_time)

    echo "$concurrency;$count;$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" >>"$time_log_path"
    echo "$concurrency;$count;$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" 
    count=$((count + 1))
  done
done
