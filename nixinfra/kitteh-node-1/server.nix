# Because this behaves as cluster init, all the "commons.server.nix" seperation
# isn't in here. However, normal commons is. Just fyi.

let 
  pkgs = import <nixpkgs> {};
  k3s_token = (import ../secrets.nix).services.k3s.token;
in {
  imports = [
    ../commons.nix
  ];

  networking.hostName = "kitteh-node-1-k3s-server";
  environment.variables.NIX_BUILD_ID = "kitteh-node-1/server";

  systemd.services.k3s = {
    enable = true;
    description = "(manual) k3s service";

    path = [
      pkgs.k3s
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "k3s-hack" ''
        k3s server --cluster-init --token ${k3s_token} --disable servicelb
      '';
    };
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