# Because this behaves as cluster init, all the "commons.server.nix" seperation
# isn't in here. However, normal commons is. Just fyi.

let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../commons.nix
  ];

  networking.hostName = "kitteh-node-1-k3s-server";
  environment.variables.NIX_BUILD_ID = "kitteh-node-1/server";
  
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