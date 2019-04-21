with import ./buildkite.nix;
with pkgs.callPackage ./tools.nix { };
with builtins;
with lib;

{
  steps = agents [[ "queue=linux" "nix=true" ] [ "queue=macos" "nix=true" ]] ([

     (step ":pipeline: Lint" {
       command = ''
         nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
           echo +++ Lint
           make lint
         NIXSH
       '';
     })

     (step ":pipeline: Test" {
        command = ''
          nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
            echo +++ Test
            make test
          NIXSH
        '';
     })

    ] ++ (if getEnv "BUILDKITE_BRANCH" == "master" then
    [

       wait

       (step ":pipeline: Populate cachix cache" {
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

    ] else []));
}