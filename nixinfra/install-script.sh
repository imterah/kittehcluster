#!/usr/bin/env bash
export TERM="xterm-256color"
clear

echo "KittehCluster installer"
echo "Codename 'tundra'"
echo

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk /dev/vda
  o # dos disk label
  n # new partition
  p # primary partition
  1 # setup boot partition
  2048 # align first sector (performance reasons?)
  +500M # boot partition size
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/vda1
  w # write the partition table
  q # and we're done
EOF

sudo mkfs.fat -F 32 /dev/vda1
sudo fatlabel /dev/vda1 BOOT
sudo mkfs.ext4 /dev/vda2 -L ROOT

sudo mount /dev/vda2 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/vda1 /mnt/boot

sudo nixos-generate-config --root /mnt

sudo mv /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix

sudo rm -rf /mnt/etc/nixos/* /mnt/etc/nixos/.*
sudo nix-shell -p git --command "git clone $GIT_REPO /mnt/etc/nixos"

if [ ! -f "/mnt/etc/nixos/install-script.sh" ]; then
  echo "DEBUG: checking out 'tundra' branch..."
  sudo nix-shell -p git --command "cd /mnt/etc/nixos; git checkout tundra"
fi

sudo mv /tmp/hardware-configuration.nix /mnt/etc/nixos/nixinfra/
sudo mv $SECRETS_PATH /mnt/etc/nixos/nixinfra/secrets.nix

sudo bash -c "NIXOS_CONFIG=/mnt/etc/nixos/nixinfra/$NIX_INSTALL_PATH nixos-install"
RET=$?

if [ $RET -ne 0 ]; then
  echo "Failed to install! Attempting to spawn bash for debugging..."
  echo "NOTE: You will not see a bash prompt (for some reason)"
  bash
  echo "Bash exited."
else
  echo "Successfully installed! Finishing install..."
  mkdir /mnt/home/clusteradm/.bin
  echo "NIX_INSTALL_PATH=/etc/nixos/nixinfra/$NIX_INSTALL_PATH" > /mnt/home/clusteradm/.bin/.env
  echo 'export PATH="$PATH:/home/clusteradm/.bin"' >> /mnt/home/clusteradm/.bashrc
  echo 'export PATH="$PATH:/home/clusteradm/.bin"' >> /mnt/home/clusteradm/.zshrc
  sleep 60
  echo "Rebooting"
  sudo reboot
  exit
fi

echo "Unmounting filesystems..."
sudo umount -f /mnt/boot
sudo umount -f /mnt
echo "Done."