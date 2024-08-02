{
  pkgs ? import <nixpkgs> { },
}: pkgs.mkShell {
  buildInputs = with pkgs; [
    python312

    # Packages
    python312Packages.pyyaml
    python312Packages.termcolor
  ];

  shellHook = ''
    ./shell
    exit $?
  '';
}
