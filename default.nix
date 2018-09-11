with import <nixpkgs> {};

stdenv.mkDerivation {
 name = "spook";
 buildInputs = [ gnumake gcc wget perl cacert tmux git glibcLocales ps gawk gnugrep ];
}
