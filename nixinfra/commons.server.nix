let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ./commons.nix
  ];

  # This is intentionally defined like this (not using braces) for updating. DO NOT CHANGE THIS.
  # - greysoh
  proxmox.qemuConf.memory = 4096;
  proxmox.qemuConf.cores = 1;
  proxmox.qemuConf.name = "k3s-server";
  proxmox.qemuConf.diskSize = pkgs.lib.mkForce "32768";

  services.k3s = {
    enable = true;
    role = "server";
    serverAddr = "https://kitteh-node-1-k3s-server:6443";
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