#!/usr/bin/env bash
set -e

echo "Building '$1'..."
nix --extra-experimental-features nix-command run github:nix-community/nixos-generators -- --format proxmox --configuration "$1.nix" | tee build.log

if [ ! -d "out/" ]; then
  mkdir out/
fi

echo "Copying file to the output directory..."

# Hacky!
mkdir -p out/$1
rm -rf out/$1 out/$1.vma.zst
OUT_FILE="$(sed -n '$p' build.log)"
cp -r $OUT_FILE out/$1.vma.zst