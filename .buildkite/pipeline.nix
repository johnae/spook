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
  steps.commands.test = {
    command = withBuildEnv ''

      echo +++ Build
      nix build
      SPOOK=$(pwd)/result/bin/spook
      export SPOOK

      echo +++ Lint
      $SPOOK -f spec/support/run_linter.lua ./*.moon lib/*.moon lib/bsd/*.moon lib/linux/*.moon
      $SPOOK -f spec/support/run_linter.lua spec/*.moon

      echo +++ Test
      $SPOOK -f spec/support/run_busted.lua spec
      ./bin/shpec
    '';
  };
}
