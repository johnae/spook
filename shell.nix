{ nixpkgs ? import <nixpkgs> { } }:
let
  spook-lint = nixpkgs.writeStrictShellScriptBin "spook-lint" ''
    export LUAJIT="${nixpkgs.luajit_2_1}/bin/luajit";
    make lint
  '';
  spook-test = nixpkgs.writeStrictShellScriptBin "spook-test" ''
    export LUAJIT="${nixpkgs.luajit_2_1}/bin/luajit";
    make test
  '';
in
nixpkgs.mkShell {
  buildInputs = [
    spook-lint
    spook-test
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
