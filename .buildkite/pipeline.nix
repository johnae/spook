with import ./buildkite.nix;

let

  cache-steps = if builtins.getEnv "BUILDKITE_BRANCH" == "master" then
  [
    wait

    (
      step ":pipeline: Populate cachix cache" {
        environment = [ "CACHIX_SIGNING_KEY" ];
        agents = [ "queue=linux" "nix=true" ];
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
      }
    )
  ] else [];

in

  pipeline ([

    (step ":pipeline: Lint" {
      agents = [ "queue=linux" "nix=true" ];
      command = ''
        nix-shell --run bash <<'NIXSH'
          echo +++ Lint
          make lint
        NIXSH
      '';
    })

    (step ":pipeline: Test" {
      agents = [ "queue=linux" "nix=true" ];
      command = ''
        nix-shell --run bash <<'NIXSH'
          echo +++ Test
          make test
        NIXSH
      '';
    })

] ++ cache-steps)