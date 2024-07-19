nix_bld_unset_err() {
  echo "ERROR: NIX_BUILD_ID is not set (should be set by default!)"
  echo "  Please set NIX_BUILD_ID manually. i.e:"
  echo "  NIX_BUILD_ID=kitteh-node-1/agent updater"
  exit 1
}

if [[ "$NIX_BUILD_ID" == "" ]]; then
  if [[ ! -f "/tmp/nixbuildid" ]]; then
    nix_bld_unset_err
  fi

  source /tmp/nixbuildid

  if [[ "$NIX_BUILD_ID" == "" ]]; then
    nix_bld_unset_err
  fi
fi

if [[ "$UID" != "0" ]]; then
  # Hacky workaround for failing to read NIX_BUILD_ID when called like:
  # - $: ./update
  # but this works:
  # - $: sudo su
  # - #: ./update
  # NOTE: Calling `$: sudo ./update` still doesn't work with this hack. Just use `./update`, man.

  echo "NIX_BUILD_ID=$NIX_BUILD_ID" > /tmp/nixbuildid
  chmod +x /tmp/nixbuildid
  
  sudo $0 $@
  STATUS_CODE=$?

  rm -rf /tmp/nixbuildid

  exit $STATUS_CODE
fi

pushd /etc/nixos 2> /dev/null > /dev/null
git pull
popd 2> /dev/null > /dev/null

export NIX_PATH="$(printf $NIX_PATH | sed --expression="s#/etc/nixos/configuration.nix#/etc/nixos/nixinfra/$NIX_BUILD_ID.nix#g")"
nixos-rebuild switch --upgrade