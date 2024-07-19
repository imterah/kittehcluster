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
        k3s agent --token ${k3s_token} --server https://kitteh-node-1-k3s-server:6443
      '';
    };
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