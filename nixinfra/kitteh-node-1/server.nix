# Because this behaves as cluster init, all the "commons.server.nix" seperation
# isn't in here. However, normal commons is. Just fyi.

let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../commons.nix
  ];

  # This is intentionally defined like this (not using braces) for updating. DO NOT CHANGE THIS.
  # - greysoh
  proxmox.qemuConf.memory = 4096;
  proxmox.qemuConf.cores = 1;
  proxmox.qemuConf.name = "k3s-server";
  proxmox.qemuConf.diskSize = pkgs.lib.mkForce "32768";

  networking.hostName = "kitteh-node-1-k3s-server";
  
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    extraFlags = "--disable servicelb";
  };

  # K3s settings
  networking.firewall = {
    enable = true;
    
    allowedTCPPorts = [
      6443
      2379
      2380
    ];

    allowedUDPPorts = [
      8472
    ];
  };
}