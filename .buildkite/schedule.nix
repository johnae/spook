with import <nixpkgs> { };
with pkgs.callPackage ./tools.nix { };

let

  schedule-build = writeStrictShellScriptBin "schedule-build" ''
    nix eval -f .buildkite/pipeline.nix --json steps | \
        buildkite-agent pipeline upload
    nix-shell -p kubectl -p gnugrep -p coreutils --run bash<<'NIXSH'
      linuxjobs=$((2 - $(kubectl get pods | grep linux-buildkite-job | grep Running | wc -l)))
      while [ "$linuxjobs" -gt 0 ]
      do
        linuxjobs=$(($linuxjobs - 1))
        kubectl create -f /jobs/linuxjob.yaml
      done
      macosjobs=$((2 - $(kubectl get pods | grep macos-buildkite-job | grep Running | wc -l)))
      while [ "$macosjobs" -gt 0 ]
      do
        macosjobs=$(($macosjobs - 1))
        kubectl create -f /jobs/macosjob.yaml
      done
    NIXSH
  '';

in

stdenv.mkDerivation {
  name = "schedule";
  buildInputs = [ schedule-build ];
}