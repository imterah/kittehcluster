# Example secrets configuration
# There is a better way to do this, but this works.

# To get started:
# 1. Copy this file to 'secrets.nix'
# 2. Run uuidgen (or some other algorithm) to generate a shared secret, and replace services.k3s.token's value with that
# 3. Profit!

let 
  pkgs = import <nixpkgs> {};
in {
  services.k3s.token = "shared.secret.here";
}