let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../commons.server.nix
  ];

  networking.hostName = "kitteh-node-2-k3s-server";
}