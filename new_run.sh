# Function to generate a unique container name
function generate_container_name() {
  local base_name="$1"
  local uid="$2"
  echo "${base_name}_${uid}"
}

function start_command() {
  local uid="$1"
  local container_name=$(generate_container_name "hpl" "$uid")
  docker run -d --name "$container_name" "$image_name" || exit 1 &
  echo $!  # Return PID for background process
}

function stop_command() {
  local uid="$1"
  local container_name=$(generate_container_name "hpl" "$uid")
  docker container stop "$container_name" || exit 1 &
  echo $!
}

function remove_container_command() {
  local uid="$1"
  local container_name=$(generate_container_name "hpl" "$uid")
  docker rm "$container_name" || exit 1 &
  echo $!
}

# Configure the number of concurrent experiments
concurrency_level=3  # Number of experiments to run in parallel

# Repeated testing configuration
max_runs=5  # Number of times to repeat the whole set of experiments

# Main loop for repeated testing
for (( run=1; run<=max_runs; run++ )); do
  echo "Starting run $run of $max_runs"

  # Array to keep track of PIDs for concurrency
  declare -a pids

  # Start experiments concurrently
  for (( i=1; i<=concurrency_level; i++ )); do
    uid=$(date +%Y%m%d%H%M%S%N)  # Generate a unique identifier
    echo "Starting experiment $i in run $run"
    start_pid=$(start_command "$uid")
    pids+=($start_pid)  # Store PID for later synchronization
  done

  # Wait for all experiments in this batch to complete startup
  for pid in "${pids[@]}"; do
    wait $pid
  done

  # Optionally perform operations that require all containers to be running simultaneously
  # (like load testing across multiple instances)

  # Now stop and remove containers
  pids=()  # Clear array for next set of PIDs
  for (( i=1; i<=concurrency_level; i++ )); do
    uid=$(date +%Y%m%d%H%M%S%N)  # Generate another unique identifier
    echo "Stopping and removing experiment $i in run $run"
    stop_pid=$(stop_command "$uid")
    remove_pid=$(remove_container_command "$uid")
    pids+=($stop_pid $remove_pid)
  done

  # Wait for all stop and removal commands to complete
  for pid in "${pids[@]}"; do
    wait $pid
  done

  echo "Completed run $run of $max_runs"
done

echo "All operations completed."
