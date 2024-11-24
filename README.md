# KittehCluster
This is my (work in progress, deployed but nothing production running on it *yet*) Kubernetes clustered computing setup, based on Proxmox VE and Ubuntu Server.

Currently, I *really* cannot recommend that you use this setup in production yet. I have to delete and recreate my VMs multiple times a day, until I fix everything.
## Prerequisites
- A POSIX-compliant computer (preferably Unix of some sort, like macOS/Linux/*BSD, but Git Bash or Cygwin would probably work) with Python and Pyyaml
- A cluster of computers preferably running Proxmox. These should (not required, but *highly* recommended) be connected together in Proxmox using the cluster feature.
- `kubectl`, and `helm` installed on your local computer.
## Setup
### VM Setup
1. First, you'll need to fork this repository, and `git clone` it down.
2. Run `nix-shell`.
3. (optional) Change `SETUP_USERNAME` to the username you want to use in `config/.env`.
4. (optional) Change `SETUP_PASSWORD` to the hashed password you want to use (genpasswd to generate this)
5. (Proxmox-specific, but you'll need to do a similar process on i.e ESXi, XenServer, etc.) Go to [the Ubuntu Server page](https://ubuntu.com/download/server), and copy the minimal ISO download. Go your ISO image volume (`local` by default), click on ISO images, click download from URL, paste in the URL, click query URL, then download the file on all of your nodes.
6. Create VM(s) that uses a VirtIO hard drive (i.e drives with `/dev/vdX`), and the ISO set to the Ubuntu Server installer.
7. On your main computer, run the command `./install.sh $PATH_TO_USE_FOR_INSTALL`, where `$PATH_TO_USE_FOR_INSTALL` is the infrastructure-defined server to use in `config/infrastructure.ini`.
8. When booting, press `e` to edit the configuration. When you see the line that says `linux` with `---` at the end of it, remove the `---` and put the command line arguments that correspond to your IP address in there. Press `F10` to boot.
9. Boot it, and let it install.
### Kubernetes setup
1. SSH into any of the nodes. (i.e `ssh clusteradm@kitteh-node-2-k3s-server`)
2. As root, grab `/etc/rancher/k3s/k3s.yaml`, and copy it to wherever you store your k3s configurations (on macOS, this is `~/.kube/config`)
3. Go into the `kubernetes` directory, and copy `example-secrets` to `secrets` and modify these to be your credentials.
4. Run `./kubesync.py`. If you recieve MetalLB errors while this happens, `rm -rf meta`, and try again. It should work on the second attempt. If not, report this issue.
## Updating
Run `apt update` and `apt upgrade -y` for the base system. TODO for Kubernetes.
## Customization
### Adding nodes
In `serverinfra/infrastructure.ini`, copy the role(s) from kitteh-node-2 to a new node (ex. `kitteh-node-2/server` -> `kitteh-node-3/server`, etc), and run the install script again.
### Custom cluster setup / Forking
This is a guide. You can change more stuff if you'd like, but this will get you started.

1. First, fork this Git repository if you haven't already.
2. Modify `serverinfra/config/infrastructure.ini` to fit your needs.
## Troubleshooting
- I can't login via SSH!
  - Your SSH public keys are automatically copied over! If not, did you generate an SSH keyring before installing?
  - Additionally, password authentication is disabled!
