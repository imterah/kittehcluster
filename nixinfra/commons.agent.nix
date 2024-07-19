let 
  pkgs = import <nixpkgs> {};
  k3s_token = (import ./secrets.nix).services.k3s.token;
in {
  imports = [
    ./commons.nix
  ];

  systemd.services.k3s = {
    enable = true;
    description = "KittehCluster's modified k3s service";

    # From L324: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/builder.nix
    path = with pkgs; [
      kmod
      socat
      iptables
      iproute2
      ipset
      bridge-utils
      ethtool
      util-linux
      conntrack-tools
      runc
      bash
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "k3s-hack" ''
        rm -rf /tmp/k3shack

        # Manually recreate the symlinks. Don't @ me.
        mkdir /tmp/k3shack

        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/containerd
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/crictl
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/ctr
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s-agent
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s-certificate
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s-completion
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s-etcd-snapshot
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s-secrets-encrypt
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s-server
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s-token
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/kubectl
        ln -s ${pkgs.k3s}/bin/.k3s-wrapped /tmp/k3shack/k3s

        export PATH=/tmp/k3shack:$PATH
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