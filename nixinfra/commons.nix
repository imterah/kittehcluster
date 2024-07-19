let 
  pkgs = import <nixpkgs> {};
  update_script = builtins.readFile ./update.sh;
in {
  imports = [
    ./secrets.nix
    ./hardware-configuration.nix
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024;
    }
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  systemd.services.kittehclean = {
    enable = true;
    description = "Cleans up this Kitteh node & runs init tasks";

    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "kittehclean" ''
        echo "KittehCluster: Running cleanup tasks..."

        chmod -R 644 /etc/rancher 2> /dev/null > /dev/null
        chmod -R 644 /var/lib/rancher 2> /dev/null > /dev/null

        # Because I'm lazy (and this works), we use this method to write the file
        rm -rf /home/clusteradm/update
        ln -s ${pkgs.writeShellScript "update" update_script} /home/clusteradm/update
        
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
  };

  environment.systemPackages = with pkgs; [
    nano
    vim
    bash
    htop
    bottom

    # Updating
    git
  ];

  system.stateVersion = "24.05";
}