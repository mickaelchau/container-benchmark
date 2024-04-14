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

count=0
max_runs=100
export image_name="hpl"
while [[ $count -lt $max_runs ]]; do
   
    load_time=$(get_command_time load_command)
    instantiate_time=$(get_command_time start_command)
    #sleep 30
    stop_time=$(get_command_time stop_command)
    container_removal_time=$(get_command_time remove_container_command)
    image_removal_time=$(get_command_time remove_image_command)
    #sleep 60
    display_date=$(get_date_time)

    echo "$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" >>"logs/dockertest"
    echo "$count;$load_time;$instantiate_time;$stop_time;$container_removal_time;$image_removal_time;$image_size;$display_date" 
    count=$((count + 1))
done


printf "\n"
