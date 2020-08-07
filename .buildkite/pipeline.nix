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
    make lint
  '';
  steps.commands.test.command = withBuildEnv ''
    echo +++ Test
    make test
  '';
}
