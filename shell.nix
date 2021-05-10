{ mkDevShell
, writeStrictShellScriptBin
, luajit_2_1
, strict-bash
, gnumake
, gcc
, wget
, perl
, cacert
, tmux
, git
, glibcLocales
, ps
, gawk
, gnugrep
}:

let
  spook-lint = writeStrictShellScriptBin "spook-lint" ''
    LUAJIT="${luajit_2_1}/bin/luajit"
    LUAJIT_SRC="${luajit_2_1.src}"
    export LUAJIT LUAJIT_SRC
    make lint
  '';
  spook-test = writeStrictShellScriptBin "spook-test" ''
    LUAJIT="${luajit_2_1}/bin/luajit"
    LUAJIT_SRC="${luajit_2_1.src}"
    export LUAJIT LUAJIT_SRC
    make test
  '';
in
mkDevShell {
  name = "spook";
  packages = [
    spook-lint
    spook-test
    luajit_2_1
    strict-bash
    gnumake
    gcc
    wget
    perl
    cacert
    tmux
    git
    glibcLocales
    ps
    gawk
    gnugrep
  ];
}
