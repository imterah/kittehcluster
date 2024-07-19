# KittehCluster
This is my (work in progress, deployed but nothing production running on it *yet*) Kubernetes clustered computing setup, based on Proxmox VE and NixOS.  
  
Currently, I cannot recommend that you use this setup in production yet. I have to delete and recreate my VMs multiple times a day, until I fix everything.
## Prerequisites
- An x86_64 computer with virtualization enabled, running NixOS
- A cluster of computers preferably running Proxmox. These should (not required, but *highly* recommended) be connected together in Proxmox using the cluster feature.
- Patience (will take a while, and may test it)
- `kubectl`, and `helm` installed on your local computer.
## Setup
### VM Setup
1. First, you'll need to fork this repository, and `git clone` it down.
2. Copy `secrets.example.nix` to `secrets.nix`.
3. Change `services.k3s.token` to be a unique token (i.e using `uuidgen`, `head -c 500 /dev/random | sha1sum | cut -d " " -f 1`, etc)
4. Change `users.users.clusteradm.openssh.authorizedKeys.keys` to have your SSH key(s) in there.
5. (Proxmox-specific, but you'll need to do a similar process on i.e ESXi, XenServer, etc.) Go to [the NixOS download page](https://nixos.org/download/), and copy the minimal ISO download. Go your ISO image volume (by default, this is `local`), click on ISO images, click download from URL, paste in the URL, click query URL, then download the file on all of your nodes.
6. Create VM(s) that use VirtIO hard drives (i.e drives with `/dev/vdX`), and the ISO set to the NixOS installer.
7. Boot the installer, and set the password of the `nixos` user to something so you can SSH in to start the installer.
8. With the environment variable `NIX_INSTALL_PATH` set to the nix file you want to use for installation (i.e `kitteh-node-1/agent.nix`), run `./install.sh IP_ADDRESS_FOR_VM_HERE`. This will take about 20 minutes on my setup. You are highly encouraged to run multiple installations in parallel.
9. When the installation is done (it will autoreboot), you can now connect using your SSH key to any of the nodes with the user `clusteradm`. The default password is `1234`. Be sure to change this!
### Kubernetes setup
1. SSH into any of the nodes. (i.e `ssh clusteradm@kitteh-node-2-k3s-server`)
2. As root, grab `/etc/rancher/k3s/k3s.yaml`, and copy it to wherever you store your k3s configurations (on macOS, this is `~/.kube/config`)
## Updating
Connect to the node using SSH, and run `./update`.
## Customization
### Adding nodes
Copy `kitteh-node-2`, to `kitteh-node-X`, where `X` is the server number. Change the hostname to correspond to each clustered computer (i.e 3rd computer's k3s agent is `kitteh-node-3-k3s-agent`)
### Custom cluster setup / Forking
This is a guide. You can change more stuff if you'd like, but this will get you started.  
  
1. First, fork this Git repository if you haven't already.
2. If you want to change the folder names, rename the folders (i.e kitteh-node-* to whatever-*), and change `buildall.sh`'s for loop to be `whatever-*/*`, for example.
3. If you want to change the hostname, change them all. Be sure to change `commons.agent.nix` and `commons.server.nix` to correspond to the new `kitteh-node-1-k3s-server`'s name!
4. In `commons.nix`, either remove `kittehclean` (not recommended unless you're using a private Git repository), or change the git repository it pulls down from (i.e change `https://git.hofers.cloud/greysoh/kittehcluster` to `https://github.com/contoso/k3s-cluster`).
5. (optional) Rename `kittehclean` and change the description.
## Troubleshooting
- I can't login via SSH!
  - Have you copied your SSH keys to the `clusteradm` user? Try copying your keys on another computer (or the VM console) if you got a new one, for example (in the `~/.ssh/authorized_keys` on each VM)
  - Additionally, password authentication is disabled!