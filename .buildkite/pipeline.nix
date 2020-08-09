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
  inherit (config.steps) commands;
in
{
  steps.commands.build.command = withBuildEnv ''
    echo +++ Building and caching spook
    nix build | cachix push insane
  '';
  steps.commands.lint = {
    dependsOn = [ commands.build ];
    command = withBuildEnv ''
      echo +++ Lint
      nix build
      SPOOK=$(pwd)/result/bin/spook
      export SPOOK
      $SPOOK -f spec/support/run_linter.lua *.moon lib/*.moon lib/bsd/*.moon lib/linux/*.moon
      $SPOOK -f spec/support/run_linter.lua spec/*.moon
    '';
  };
  steps.commands.test = {
    dependsOn = [ commands.build ];
    command = withBuildEnv ''
      echo +++ Test
      nix build
      SPOOK=$(pwd)/result/bin/spook
      export SPOOK
      $SPOOK -f spec/support/run_busted.lua spec
      ./bin/shpec
    '';
  };
}
