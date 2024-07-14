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

  services.k3s = {
    enable = true;
  };

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

  users.users.greysoh = {
    initialPassword = "1234";
    isNormalUser = true;
    extraGroups = ["sudoer" "wheel" "docker"];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgQP14EBe0r9QnLnDy00vMhlmmo62FJnY/MqNMm0K3qQZTQSkRaBsSYHI10KcLlPEwe266opLOirLG+O0xYDi192hm+vSVfa921r1Dva0on22D5mIKg9Zx50csOTduXngnAnFnlX/W7J0zJAjcFMMTU/wCXZA50KP5a86BJzHb3lErD18cb7h8E5QhasMmEwe5kkJVB2Ys8rZqZTn8XNZ8+7Dv0RUSqMpNkVhI3U+Xcl8Q7wP8Bm6lyYkI53Wlicz2VOssfUlQA0Y2AifJDlXKK6QFDVQ9nE4qCCjiOYtkz1mIepMXxfTY1vV7RUrBHbzEIeYt8TfSuYpB/0mcnGTUHwvQBlNPwZMCxPYPxaPqYm/amb4DfhgU2m8nEAZEfC4KC/z6PBN8JPMb8NthXsSalpXsjmKjhLU4SsBvrm3y/diAS2hs6Fo2bcHg0a5qNw7nL/WFagK9fUyvQY/rAzIdbfL2ZL59Aul/nqz8dWQMdZbND1DORKzxW6lmbBqZPL8= root@zeus-proxmox"
    ];

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
  ];

  system.stateVersion = "24.05";
}