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
sudo nixos-install -I /mnt/etc/nixos/nixinfra/$NIX_INSTALL_PATH

sudo umount /mnt/boot
sudo umount /mnt