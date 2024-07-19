let 
  pkgs = import <nixpkgs> {};
  k3s_token = (import ./secrets.nix).services.k3s.token;
in {
  imports = [
    ./commons.nix
  ];

  systemd.services.k3s = {
    enable = true;
    description = "(manual) k3s service";

    path = [
      pkgs.k3s
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "k3s-hack" ''
        k3s server --token ${k3s_token} --server https://kitteh-node-1-k3s-server:6443 --disable servicelb
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