{
  pkgs ? import (
    fetchTarball "https://github.com/NixOS/nixpkgs/archive/19.03.tar.gz") {},
}:

let
  callPackage = pkgs.lib.callPackageWith(pkgs // pkgs.xlibs // self);
  self = rec {
    rEnv = (pkgs.rWrapper.override {
      packages = [
        pkgs.rPackages.tidyverse
        pkgs.rPackages.viridis
        pkgs.rPackages.docopt
        pkgs.rPackages.ggrepel
      ];
    });
    pyEnv = (pkgs.python37.withPackages (ps: [
      ps.pandas
    ])).env;
  };
in
  self
