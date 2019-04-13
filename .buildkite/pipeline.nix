with import ./buildkite.nix;
with builtins;
with lib;

let

  ## build on macos as well when infra is in place
  #run-on-agents = [["queue=linux" "nix=true"]
  #          ["queue=macos" "nix=true"]];
  run-on-agents = [[ "queue=linux" "nix=true" ]];

in

  pipeline (

   flatten (map (agents: [

     (step ":pipeline: Lint" {
       inherit agents;
       command = ''
         nix-shell --run bash <<'NIXSH'
           echo +++ Lint
           make lint
         NIXSH
       '';
     })

    (step ":pipeline: Test" {
       inherit agents;
       command = ''
         nix-shell --run bash <<'NIXSH'
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
           echo --- Populate cachix cache
           if [ -z "$CACHIX_SIGNING_KEY" ]; then
              echo "Missing environment variable CACHIX_SIGNING_KEY"
              exit 1
           fi
           nix-env -iA cachix -f https://cachix.org/api/v1/install
           nix-store -qR --include-outputs "$(nix-instantiate build.nix)" | \
           tee /dev/tty | \
           cachix push insane
         '';
         })
     ]
    else [])
    )
   run-on-agents ## map
  )
)