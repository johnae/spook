{ config, pkgs, lib, ... }:
## Generate the buildkite json like this on the command line:
##
## nix eval .#buildkite.pipeline --json
let
  withBuildEnv = cmd: ''
    eval "$(nix print-dev-env)"
    strict-bash <<'NIXSH'
    set -eou pipefail
    ${cmd}
    NIXSH
  '';
in
{
  steps.commands.lint.command = withBuildEnv ''
    echo +++ Lint
    nix build
    SPOOK=$(pwd)/result/bin/spook
    export SPOOK
    spook-lint
  '';
  steps.commands.test.command = withBuildEnv ''
    echo +++ Test
    nix build
    SPOOK=$(pwd)/result/bin/spook
    export SPOOK
    spook-test
  '';
}
