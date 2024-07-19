#!/usr/bin/env bash
if [ "$GIT_REPO" == "" ]; then
  export GIT_REPO="https://git.hofers.cloud/greysoh/kittehcluster"
fi

if [ "$NIX_INSTALL_PATH" == "" ]; then
  echo "ERROR: the environment variable 'NIX_INSTALL_PATH' is not set!"
  echo "This can be fixed by setting it to the path of the nix file, i.e:"
  echo "$ NIX_INSTALL_PATH=kitteh-node-1/server.nix ./install.sh"
  exit 1
fi

echo "Initializing..."
FILE_ENCODED="$(cat install-script.sh | base64)"
ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" nixos@$1 bash -c "'echo -n $FILE_ENCODED | base64 -d > /tmp/install.sh; GIT_REPO=$GIT_REPO NIX_INSTALL_PATH=$NIX_INSTALL_PATH bash /tmp/install.sh'"