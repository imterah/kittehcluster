#!/usr/bin/env bash
if [[ "$NIX_BUILD_ID" == "" ]]; then
  echo "ERROR: You have held a (potentially) broken install!"
  echo "NIX_BUILD_ID is not set (should be set by default!)"
  echo "Please set NIX_BUILD_ID manually. i.e:"
  echo "NIX_BUILD_ID=kitteh-node-1/agent updater"
  exit 1
fi

if [[ "$UID" != "0" ]]; then
  sudo $0 $@
  exit $?
fi

export NIX_PATH="$(printf $NIX_PATH | sed --expression="s#/etc/nixos/configuration.nix#/etc/nixos/nixinfra/$NIX_BUILD_ID.nix#g")"
nixos-rebuild switch --upgrade