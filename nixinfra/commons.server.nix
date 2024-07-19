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

    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "k3s-hack" ''
        if [ ! -d "/tmp/k3shack" ]; then
          # Manually recreate the symlinks. Don't @ me.
          mkdir /tmp/k3shack
          
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/containerd
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/crictl
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/ctr
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/k3s-agent
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/k3s-certificate
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/k3s-completion
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/k3s-etcd-snapshot
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/k3s-secrets-encrypt
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/k3s-server
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/k3s-token
          ln -s ${pkgs.k3s}/bin/k3s /tmp/k3shack/kubectl
        fi

        export PATH=$PATH:/tmp/k3shack
        ${pkgs.k3s}/bin/k3s server --token ${k3s_token} --server https://kitteh-node-1-k3s-server:6443 --disable servicelb
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