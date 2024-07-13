let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../secrets.nix
  ];

  proxmox.qemuConf.memory = 4096;
  proxmox.qemuConf.cores = 1;
  proxmox.qemuConf.name = "k3s-server";
  proxmox.qemuConf.diskSize = pkgs.lib.mkForce "16384";

  networking.hostName = "kitteh-node-2-k3s-server";

  services.k3s = {
    enable = true;
    role = "server";
    serverAddr = "kitteh-node-1-k3s-server:6443";
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
    (pkgs.lib.mkBefore [ "mdns4_minimal [NOTFOUND=return]" ]) # before resolution
    (pkgs.lib.mkAfter [ "mdns4" ]) # after dns
  ]);

  users.users.greysoh = {
    initialPassword = "1234";
    isNormalUser = true;
    extraGroups = ["sudoer" "wheel"];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgQP14EBe0r9QnLnDy00vMhlmmo62FJnY/MqNMm0K3qQZTQSkRaBsSYHI10KcLlPEwe266opLOirLG+O0xYDi192hm+vSVfa921r1Dva0on22D5mIKg9Zx50csOTduXngnAnFnlX/W7J0zJAjcFMMTU/wCXZA50KP5a86BJzHb3lErD18cb7h8E5QhasMmEwe5kkJVB2Ys8rZqZTn8XNZ8+7Dv0RUSqMpNkVhI3U+Xcl8Q7wP8Bm6lyYkI53Wlicz2VOssfUlQA0Y2AifJDlXKK6QFDVQ9nE4qCCjiOYtkz1mIepMXxfTY1vV7RUrBHbzEIeYt8TfSuYpB/0mcnGTUHwvQBlNPwZMCxPYPxaPqYm/amb4DfhgU2m8nEAZEfC4KC/z6PBN8JPMb8NthXsSalpXsjmKjhLU4SsBvrm3y/diAS2hs6Fo2bcHg0a5qNw7nL/WFagK9fUyvQY/rAzIdbfL2ZL59Aul/nqz8dWQMdZbND1DORKzxW6lmbBqZPL8= root@zeus-proxmox"
    ];
  };

  environment.systemPackages = with pkgs; [
    nano
    vim
    bash
    htop
    bottom
  ];

  networking.firewall = {
    enable = true;
    
    allowedTCPPorts = [
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

  system.stateVersion = "24.05";
}