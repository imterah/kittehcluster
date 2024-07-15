let 
  pkgs = import <nixpkgs> {};
  secret_data = builtins.readFile ./secrets.nix;
in {
  imports = [
    ./secrets.nix
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024;
    }
  ];

  services.k3s.enable = true;

  systemd.services.kittehclean = {
    enable = true;
    description = "Cleans up this Kitteh node & runs init tasks";

    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "kittehclean" ''
        echo "KittehCluster: Running cleanup tasks..."

        chmod -R 644 /etc/rancher 2> /dev/null > /dev/null
        chmod -R 644 /var/lib/rancher 2> /dev/null > /dev/null

        if [ ! -d "/etc/nixos/git" ]; then
          echo "Waiting for true internet bringup..."
          sleep 10
          echo "Downloading configuration files..."
          ${pkgs.git}/bin/git clone https://git.hofers.cloud/greysoh/kittehcluster /etc/nixos/
          cp -r ${pkgs.writeText "secrets.nix" secret_data} /etc/nixos/nixinfra/secrets.nix
        fi

        echo "Done."
      '';
    };
    
    wantedBy = ["network-online.target"];
  };

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  services.avahi.enable = true;
  services.avahi.openFirewall = true;
  
  system.nssModules = pkgs.lib.optional true pkgs.nssmdns;
  system.nssDatabases.hosts = pkgs.lib.optionals true (pkgs.lib.mkMerge [
    (pkgs.lib.mkBefore ["mdns4_minimal [NOTFOUND=return]"]) # before resolution
    (pkgs.lib.mkAfter  ["mdns4"]) # after dns
  ]);

  users.users.clusteradm = {
    initialPassword = "1234";
    isNormalUser = true;
    extraGroups = ["sudoer" "wheel" "docker"];

    packages = with pkgs; [
      git
    ];
  };

  environment.systemPackages = with pkgs; [
    nano
    vim
    bash
    htop
    bottom

    # For some reason, after seperation, this package isn't included anymore, but the services are
    k3s
  ];

  system.stateVersion = "24.05";
}