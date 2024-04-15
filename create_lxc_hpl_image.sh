#!/bin/bash

hpl_script="install-hpl.sh"
new_image_tmp_repo="/tmp/sid-lxd"
hpl_image_name="hpl-lxc-image"

# Install required packages.
sudo apt install debootstrap

# Install Debian Sid (base image).
mkdir "$new_image_tmp_repo"
sudo debootstrap sid "$new_image_tmp_repo"

# Copy HPL installation script to base image.
sudo cp "$hpl_script" "$new_image_tmp_repo"/root/install-hpl.sh

# Run installation script.
sudo chroot "$new_image_tmp_repo" /bin/bash -c '
    cd /root
    chmod 777 install-hpl.sh
    sh install-hpl.sh
    exit
'

# Compress system root directory.
sudo tar -cvzf "$hpl_image_name".tar.gz -C "$new_image_tmp_repo" .

# Create metadata file.
creation_date="$(date +%s)"
echo 'architecture: "x86_64"
creation_date: '"$creation_date"'
properties:
  architecture: "x86_64"
  description: "Debian Unstable (sid) with HPL benchmark installed"
  os: "debian"
  release: "sid"' > metadata.yaml

# Create a tarball from the metadata file.
tar -cvzf metadata.tar.gz metadata.yaml

# Delete temporary repository.
sudo rm -r "$new_image_tmp_repo"

# Import LXD image.
# lxc image import metadata.tar.gz "$hpl_image_name".tar.gz --alias "$hpl_image_name"

# Make LXD image public.
# lxc config set core.https_address "[::]:8443"
# lxc image edit "$hpl_image_name"
# echo "Please modify the 'public' parameter to 'true' and save the file. Press Enter when done."
# read -r