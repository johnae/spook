with import ./buildkite.nix;
pipeline [

  (step ":pipeline: Build and Test" {
    environment = [ "CACHIX_SIGNING_KEY" ];
    agents = [ "queue=linux" "nix=true" ];
    command = ''
      nix-shell --run bash <<'NIXSH'
        echo --- Build spook
        make

        echo +++ Lint
        make lint

        echo +++ Test
        make test
      NIXSH
    '';
  })

]