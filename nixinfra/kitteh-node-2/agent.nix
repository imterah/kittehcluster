let 
  pkgs = import <nixpkgs> {};
in {
  imports = [
    ../commons.agent.nix
  ];

  networking.hostName = "kitteh-node-2-k3s-agent";
  environment.variables.NIX_BUILD_ID = "kitteh-node-2/agent";
}