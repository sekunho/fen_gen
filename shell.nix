{ pkgs ? import <nixpkgs> {} }:
  
with pkgs;

let
  inherit (lib) optional optionals;

  unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) { };

  nodejs = nodejs-14_x;
  imagemagick = unstable.imagemagick;
in

mkShell {
  LOCALE_ARCHIVE_2_27 = "${glibcLocales}/lib/locale/locale-archive";

  buildInputs = [cacert git nodejs python39 imagemagick]
    ++ optional stdenv.isLinux libnotify
    ++ optional stdenv.isLinux inotify-tools;

  shellHook = ''
  alias python=python3
  '';
}