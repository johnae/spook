## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --json steps

with import <insanepkgs> { };
with builtins;
with lib;
with buildkite-pipeline;

{

  steps = pipeline ([

    (step ":pipeline: Lint" {
      agents = { queue = "linux"; };
      command = ''
        nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
          echo +++ Lint
          make lint
        NIXSH
      '';
    })


    (step ":pipeline: Test" {
       agents = { queue = "linux"; };
       command = ''
         nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
           echo +++ Test
           make test
         NIXSH
       '';
    })

  ]);
}