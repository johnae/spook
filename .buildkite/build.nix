with import <nixpkgs> { };
with pkgs.callPackage ./tools.nix { };
stdenv.mkDerivation {
  name = "build";
  buildInputs = [ strict-bash ];
}