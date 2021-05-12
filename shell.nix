{ pkgs ? import <nixpkgs> {} }:
  
with pkgs;

let
  inherit (lib) optional optionals;

  unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) { };
  erlang = beam.interpreters.erlangR23;
  elixir = beam.packages.erlangR23.elixir_1_11;
  nodejs = nodejs-14_x;
  doctl = unstable.doctl;
  buildah = unstable.buildah;
  skopeo = unstable.skopeo;
  podman = unstable.podman;
in

mkShell {
  LOCALE_ARCHIVE_2_27 = "${glibcLocales}/lib/locale/locale-archive";

  buildInputs = [cacert git erlang elixir nodejs doctl python38 buildah skopeo podman]
    ++ optional stdenv.isLinux libnotify
    ++ optional stdenv.isLinux inotify-tools;
}