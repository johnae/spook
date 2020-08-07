{ nixpkgs ? import <nixpkgs> { } }:

nixpkgs.mkShell {
  buildInputs = [
    nixpkgs.strict-bash
    nixpkgs.gnumake
    nixpkgs.gcc
    nixpkgs.wget
    nixpkgs.perl
    nixpkgs.cacert
    nixpkgs.tmux
    nixpkgs.git
    nixpkgs.glibcLocales
    nixpkgs.ps
    nixpkgs.gawk
    nixpkgs.gnugrep
  ];
}
