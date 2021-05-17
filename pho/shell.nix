{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/ac60476ed94fd5424d9f3410c438825f793a8cbb.tar.gz") {} }:
  
with pkgs;

let
  inherit (lib) optional optionals;

  nodejs = nodejs-14_x;
  erlang = beam.interpreters.erlangR23;
  elixir = beam.packages.erlangR23.elixir;
in

mkShell {
  LOCALE_ARCHIVE_2_27 = "${glibcLocales}/lib/locale/locale-archive";

  buildInputs = [cacert nodejs python39 elixir erlang]
    ++ optional stdenv.isLinux libnotify
    ++ optional stdenv.isLinux inotify-tools;
}