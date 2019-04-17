with import <nixpkgs> { };
with pkgs.callPackage ./tools.nix { };
stdenv.mkDerivation {
  name = "build";

  buildInputs = [ gnumake gcc wget perl cacert tmux git glibcLocales ps gawk gnugrep strict-bash ];
}