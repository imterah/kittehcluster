#!/usr/bin/env bash
sudo apt update
sudo apt install -y curl avahi-daemon

ufw allow 6443/tcp
ufw allow from 10.42.0.0/16 to any
ufw allow from 10.43.0.0/16 to any

curl "https://get.docker.com/" -L | bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://$UPSTREAM_HOSTNAME:6443 --token $K3S_TOKEN" sh -s -