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

# Usage in your main loop with iteration passed
count=0
while [[ $count -lt $max_runs ]]; do
  progress $count "$max_runs"
  download_time=$(get_command_time_and_monitor_resources "download_command" "$count")
  load_time=$(get_command_time_and_monitor_resources "load_command" "$count")
  # Continue with other commands as necessary
  count=$((count + 1))
done
