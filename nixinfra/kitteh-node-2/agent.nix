let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../commons.agent.nix
  ];

  networking.hostName = "kitteh-node-2-k3s-agent";
}