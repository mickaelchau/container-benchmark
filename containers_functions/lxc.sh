#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$DIR/../config.sh"

function download_command() {
  scp root@$server_link:"/root/$service/$image_name.tar.gz" image.tar.gz
}

function load_command() {
  lxc image import hpl_lxc.tar.gz --alias "$image_name"
}

function start_command() {
  declare -a pids
  for concurrency in $(seq 1 $1); do
    lxc launch "$image_name" "hpl-$concurrency" || exit 1 &
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
    lxc stop "hpl-$concurrency" || exit 1 &
    pids+=($!)
  done
  # Wait for all experiments in this batch to complete startup
  for pid in "${pids[@]}"; do
    wait $pid
  done
}

function remove_image_command() {
  lxc image delete "$image_name" || exit 1
}

function remove_container_command() {
  declare -a pids
  for concurrency in $(seq 1 $1); do
    lxc delete --force "hpl-$concurrency" || exit 1 &
    pids+=($!)
  done
  # Wait for all experiments in this batch to complete startup
  for pid in "${pids[@]}"; do
    wait $pid
  done
}

function get_up_time() {
  lxc exec "$image_name" -- cat /root/log.txt || exit 1
}

function is_image_available() {
  lxc image list | grep "$image_name" | awk '{print $4}'
}
