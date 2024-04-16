#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$DIR/../config.sh"

function download_command() {
  scp root@$server_link:"/root/$service/$image_name.tar.gz" image.tar.gz
}

function load_command() {
  lxc image import image.tar.gz --alias "$image_name"
}

function start_command() {
  lxc launch "$image_name" "hpl-$concurrency" || exit 1
}

function stop_command() {
  lxc stop "hpl-$concurrency" || exit 1
}

function remove_image_command() {
  lxc image delete "$image_name" || exit 1
}

function remove_container_command() {
  lxc delete --force "hpl-$concurrency" || exit 1

}

function get_up_time() {
  lxc exec "$image_name" -- cat /root/log.txt || exit 1
}

function is_image_available() {
  lxc image list | grep "$image_name" | awk '{print $4}'
}
