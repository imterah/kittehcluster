let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../commons.agent.nix
  ];

  networking.hostName = "kitteh-node-1-k3s-agent";
}