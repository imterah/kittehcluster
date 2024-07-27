let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../commons.server.nix
  ];

  networking.hostName = "kitteh-node-2-k3s-server";
  environment.variables.NIX_BUILD_ID = "kitteh-node-2/server";
}