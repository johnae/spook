with import <insanepkgs> { };
with pkgs;
stdenv.mkDerivation {
  name = "build";
  buildInputs = [
                  insane-lib.strict-bash
                  gnumake gcc wget perl
                  cacert tmux git
                  glibcLocales ps gawk
                  gnugrep
                ];
}