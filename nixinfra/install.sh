#!/usr/bin/env bash
SSH_SERVER="$1"

ssh-to-srv() {
  ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" nixos@$SSH_SERVER $@
}

if [ "$GIT_REPO" == "" ]; then
  export GIT_REPO="https://git.hofers.cloud/greysoh/kittehcluster"
fi

if [ "$NIX_INSTALL_PATH" == "" ]; then
  echo "ERROR: the environment variable 'NIX_INSTALL_PATH' is not set!"
  echo "This can be fixed by setting it to the path of the nix file, i.e:"
  echo "$ NIX_INSTALL_PATH=kitteh-node-1/server.nix ./install.sh"
  exit 1
fi

if [ ! -f "secrets.nix" ]; then
  echo "ERROR: secrets.nix doesn't exit! Copy that file, and setup your secrets, please."
  exit 1
fi

echo "Initializing..."

# Ugh, gotta reimplement ssh-copy-id real quick...
# TODO: see if there's a way to specify custom arguments to ssh-copy-id's SSH process
for i in ~/.ssh/id_*.pub; do
  echo "Copying public key '$i'..."
  ssh-to-srv bash -c "'mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; echo -n $(cat $i | base64) | base64 -d > ~/.ssh/authorized_keys'"
done

ssh-to-srv bash -c "'echo -n $(cat secrets.nix | base64) | base64 -d > /tmp/secrets.nix'"
ssh-to-srv bash -c "'echo -n $(cat install-script.sh | base64) | base64 -d > /tmp/install.sh'"
ssh-to-srv bash -c "'GIT_REPO=$GIT_REPO NIX_INSTALL_PATH=$NIX_INSTALL_PATH SECRETS_PATH=/tmp/secrets.nix bash /tmp/install.sh'"