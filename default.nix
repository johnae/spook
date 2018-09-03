with import <nixpkgs> {};

stdenv.mkDerivation {
 name = "spook";
 buildInputs = [ gnumake gcc wget perl cacert tmux git ];
 shellInit = ''
   export LC_ALL=en_US.UTF-8
   export LANG=en_US.UTF-8
   export LANGUAGE=en_US.UTF-8
 '';
}
