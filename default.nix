{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3847a2a8595bba68214ac4b7e3da3fc00776989b.tar.gz") {} }:

with pkgs;

# TODO: This could definitely be improved. Especially with the inheriting of `pkgs`.

stdenv.mkDerivation {
  pname = "fengen";
  version = "0.1.0";

  src = ./.;

  buildInputs = [ (import ./nix/packages.nix { inherit pkgs; }) ];
  # propagatedBuildInputs = [ (import ./nix/runtime.nix { inherit pkgs; }) ];
  
  # Need `export HOME$(mktemp -d)` because otherwise
  # there will be a permission issue, and hex won't
  # be able to create the directory it needs.
  #
  # https://github.com/NixOS/nixpkgs/pull/83816

  buildPhase = ''
    export HOME=$(mktemp -d)
    export MIX_ENV=prod

    mix do local.hex --force, local.rebar --force
    mix do deps.get, deps.compile

    npm install --prefix ./assets
    npm run deploy --prefix ./assets

    mix do compile, phx.digest, release --overwrite
  '';

  installPhase = ''
    cp -R _build $out
    cp -R priv $out
    cp -R config $out
    cp -R lib $out
    cp -R deps $out
    cp mix.* $out
  '';
}
