{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3847a2a8595bba68214ac4b7e3da3fc00776989b.tar.gz") {} }:
  
with pkgs;

let
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "refs/tags/3.3.0";
  }) {
    python = "python38";
  };

  tensorflow = mach-nix.mkPython {
    requirements = ''
      tensorflow==2.5.0
      scikit-image==0.18.1
      numpy==1.19.2
    '';
  };

  erlang = beam.interpreters.erlangR24;
in
buildEnv {
  name = "fengen";

  paths = [ tensorflow erlang ];
}