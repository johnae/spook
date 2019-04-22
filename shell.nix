{ pkgs ? import <nixpkgs> {} }:

with pkgs; mkShell {
   buildInputs = [ gnumake gcc wget perl cacert tmux git glibcLocales ps gawk gnugrep ];
}