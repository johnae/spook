{ nixpkgs ? import <nixpkgs> { } }:
let
  spook-lint = nixpkgs.writeStrictShellScriptBin "spook-lint" ''
    LUAJIT="${nixpkgs.luajit_2_1}/bin/luajit"
    LUAJIT_SRC="${nixpkgs.luajit_2_1.src}"
    export LUAJIT LUAJIT_SRC
    make lint
  '';
  spook-test = nixpkgs.writeStrictShellScriptBin "spook-test" ''
    LUAJIT="${nixpkgs.luajit_2_1}/bin/luajit"
    LUAJIT_SRC="${nixpkgs.luajit_2_1.src}"
    export LUAJIT LUAJIT_SRC
    make test
  '';
in
nixpkgs.mkShell {
  buildInputs = [
    spook-lint
    spook-test
    nixpkgs.luajit_2_1
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
