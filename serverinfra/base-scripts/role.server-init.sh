#!/usr/bin/env bash
sudo apt update
sudo apt install -y curl

ufw allow 6443/tcp
ufw allow from 10.42.0.0/16 to any
ufw allow from 10.43.0.0/16 to any

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --token $K3S_TOKEN --disable servicelb" sh -s -