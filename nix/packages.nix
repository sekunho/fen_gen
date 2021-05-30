{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3847a2a8595bba68214ac4b7e3da3fc00776989b.tar.gz") {} }:

with pkgs;

let
  inherit (lib) optional optionals;

  nodejs = nodejs-14_x;
  erlang = beam.interpreters.erlangR24;
  elixir = beam.packages.erlangR24.elixir_1_12;
in
buildEnv {
  name = "packages";

  paths = with python38Packages; [
    elixir
    erlang
    nodejs
    python38
    pip
  ];
}