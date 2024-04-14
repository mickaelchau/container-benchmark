#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$DIR/../config.sh"

function download_command() {
  scp root@"$server_link":/root/$service/$image_name.tar image.tar
}

function load_command() {
  docker load -i hpl.tar
}

function start_command() {
  #echo "yo22 $image_name"
  declare -a pids
  for concurrency in $(seq 1 $1); do
    docker run -d  --name "hpl-$concurrency" "$image_name" || exit 1 &
    pids+=($!)
  done
  #ps
  # Wait for all experiments in this batch to complete startup
  for pid in "${pids[@]}"; do
    wait $pid
  done
}

function stop_command() {
  declare -a pids
  for concurrency in $(seq 1 $1); do
    docker container stop "hpl-$concurrency" || exit 1 &
    pids+=($!)
  done
  # Wait for all experiments in this batch to complete startup
  for pid in "${pids[@]}"; do
    wait $pid
  done
}

function remove_image_command() {
  docker rmi "$image_name" || exit 1 
}

function remove_container_command() {
  declare -a pids
  for concurrency in $(seq 1 $1); do
    docker rm "hpl-$concurrency" || exit 1 &
    pids+=($!)
  done
  # Wait for all experiments in this batch to complete startup
  for pid in "${pids[@]}"; do
    wait $pid
  done
}

function get_up_time() {
  docker exec -it hpl sh -c "test -e /root/log.txt && cat /root/log.txt"
}

function is_image_available() {
  docker image ls -a | grep "$image_name" | awk '{print $3}'
}
