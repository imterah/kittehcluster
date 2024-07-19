let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ./commons.nix
  ];

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