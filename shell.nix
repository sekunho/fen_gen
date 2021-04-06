{ pkgs ? import <nixpkgs> {} }:
  
with pkgs;

let
  inherit (lib) optional optionals;
  unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) { };
  keras = python38Packages.Keras;
  pylint = python38Packages.pylint;
  tensorflow = unstable.python38Packages.tensorflow;
  nodejs = nodejs-14_x;
in
mkShell {
  LOCALE_ARCHIVE_2_27 = "${glibcLocales}/lib/locale/locale-archive";

  buildInputs = [git keras pylint tensorflow nodejs]
    ++ optional stdenv.isLinux libnotify
    ++ optional stdenv.isLinux inotify-tools;
}