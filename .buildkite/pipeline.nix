with import ./buildkite.nix;
with pkgs.callPackage ./tools.nix { };
with builtins;
with lib;

let

  ## build on macos as well when infra is in place
  #run-on-agents = [["queue=linux" "nix=true"]
  #          ["queue=macos" "nix=true"]];
  run-on-agents = [[ "queue=linux" "nix=true" ]];

in

  { pipeline = flatten (map (agents: [

     (step ":pipeline: Lint" {
       inherit agents;
       command = ''
         nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
           echo +++ Lint
           make lint
         NIXSH
       '';
     })

    (step ":pipeline: Test" {
       inherit agents;
       command = ''
         nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
           echo +++ Test
           make test
         NIXSH
       '';
    })

   ]

   ++

   (if getEnv "BUILDKITE_BRANCH" == "master" then
     [
       wait
       (step ":pipeline: Populate cachix cache" {
         inherit agents;
         environment = [ "CACHIX_SIGNING_KEY" ];
         command = ''
           nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
             echo --- Populate cachix cache
             nix-env -iA cachix -f https://cachix.org/api/v1/install
             nix-store -qR --include-outputs "$(nix-instantiate build.nix)" | \
             tee /dev/tty | \
             cachix push insane
           NIXSH
         '';
         })
     ]
    else [])
    )
  run-on-agents); }