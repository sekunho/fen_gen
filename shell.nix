{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3847a2a8595bba68214ac4b7e3da3fc00776989b.tar.gz") {} }:
  
with pkgs;

let
  inherit (lib) optional optionals;
  nodejs = nodejs-14_x;
  erlang = beam.interpreters.erlangR24;
  elixir = beam.packages.erlangR24.elixir_1_12;
  podman = pkgs.podman;

  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "refs/tags/3.3.0";
  }) {
    python = "python38";
  };

  tensorflow = mach-nix.mkPython {
    requirements = ''
      tensorflow==2.5.0
      scikit-image
      numpy==1.19.2
    '';
  };
in
mkShell {
  LOCALE_ARCHIVE_2_27 = "${glibcLocales}/lib/locale/locale-archive";

  buildInputs = with python38Packages; [
    cacert
    nodejs
    elixir
    erlang
    python38
    tensorflow
    inotify-tools
  ];

  shellHook = ''
    export LANG="en_US.UTF-8";
    export LC_TYPE="en_US.UTF-8";
  '';
}