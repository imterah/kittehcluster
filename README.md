# KittehCluster
This is my (work in progress, deployed but nothing production running on it *yet*) Kubernetes clustered computing setup, based on Proxmox VE and NixOS.  
  
Currently, I cannot recommend that you use this setup in production yet. I have to delete and recreate my VMs multiple times a day, until I fix everything.
## Prerequisites
- An x86_64 computer with virtualization enabled, running NixOS
- A cluster of computers running Proxmox, with your SSH keys copied to them. These should (not required, but *highly* recommended) be connected together in Proxmox using the cluster feature.
- Cluster hypervisor's IPs next to eachother (ex. node 1's Proxmox is `192.168.0.20`, node 2's is `192.168.0.21`)
- Patience (will take a while, and may test it)
- `kubectl`, and `helm` installed on your local computer.
## Setup
### VM Setup
1. First, you'll need to fork this repository, and `git clone` it down.
2. Copy `secrets.example.nix` to `secrets.nix`.
3. Change `services.k3s.token` to be a unique token (i.e. using `uuidgen`, `head -c 500 /dev/random | sha1sum | cut -d " " -f 1`, etc)
4. Change `users.users.clusteradm.openssh.authorizedKeys.keys` to have your SSH key(s) in there.
5. Then, run `./buildall.sh`, to build all the virtual machines. This may take a long time, depending on your hardware! On a 2015 MacBook Air, this took 30 minutes. Make some tea while you wait!
6. Finally, run `BASE_IP=your_base_ip_here ./upload.sh -i -d`, with `BASE_IP` being the first IP for your Proxmox cluster.
7. Set all VMs to auto-start, then turn them all on, starting with the first node's `k3s-server`.
8. You can now connect using your SSH key to any of the nodes with the user `clusteradm`. The default password is `1234`. Be sure to change this!
### Kubernetes setup
1. SSH into any of the nodes. (i.e. `ssh clusteradm@kitteh-node-2-k3s-server`)
2. As root, grab `/etc/rancher/k3s/k3s.yaml`, and copy it to wherever you store your k3s configurations (on macOS, this is `~/.kube/config`)
## Updating (TODO)
In NixOS, instead of `apt update; apt upgrade -y`, `pacman -Syu --noconfirm`, or other systems, you need to "rebuild" the system.  
  
There is a work in progress of this system (see `kittehclean`'s Git downloader), but it is not done yet.
## Customization
### Adding nodes
Copy `kitteh-node-2`, to `kitteh-node-X`, where `X` is the server number. Change the hostname to correspond to each clustered computer (ex. 3rd computer's k3s agent is `kitteh-node-3-k3s-agent`)
### Custom cluster setup / Forking
This is a guide. You can change more stuff if you'd like, but this will get you started.  
  
1. First, fork this Git repository if you haven't already.
2. If you want to change the folder names, rename the folders (i.e. kitteh-node-* to whatever-*), and change `buildall.sh`'s for loop to be `whatever-*/*`, for example.
3. If you want to change the hostname, change them all. Be sure to change `commons.agent.nix` and `commons.server.nix` to correspond to the new `kitteh-node-1-k3s-server`'s name!
4. In `commons.nix`, either remove `kittehclean` (not recommended unless you're using a private Git repository), or change the git repository it pulls down from (i.e. change `https://git.hofers.cloud/greysoh/kittehcluster` to `https://github.com/contoso/k3s-cluster`).
5. (optional) Rename `kittehclean` and change the description.
## Troubleshooting
- I can't login via SSH!
  - Have you copied your SSH keys to the `clusteradm` user? Try copying your keys on another computer (or the VM console) if you got a new one, for example (in the `~/.ssh/authorized_keys` on each VM)
  - Additionally, password authentication is disabled!