let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ./commons.nix
  ];

  # This is intentionally defined like this (not using braces) for updating. DO NOT CHANGE THIS.
  # - greysoh
  proxmox.qemuConf.memory = 8192;
  proxmox.qemuConf.cores = 4;
  proxmox.qemuConf.name = "k3s-agent";
  proxmox.qemuConf.diskSize = pkgs.lib.mkForce "131072";

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://kitteh-node-1-k3s-server:6443";
    extraFlags = "--disable servicelb";
  };

  virtualisation.docker.enable = true;

  networking.firewall = {
    enable = true;
    
    allowedTCPPorts = [
      # HTTP(s)
      80
      443

      # Docker swarm
      2377
      7946
      4789

      # K3s
      6443
      2379
      2380
    ];

    allowedUDPPorts = [
      # Docker swarm
      7946

      # K3s
      8472
    ];
  };
}