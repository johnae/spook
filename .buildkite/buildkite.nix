with import <nixpkgs> {};
with lib;

let

  writeStrictShellScript = name: text:
    writeTextFile {
      inherit name;
      executable = true;
      text = ''
        #!${stdenv.shell}
        set -euo pipefail
        ${text}
      '';
      checkPhase = ''
        ## check the syntax
        ${stdenv.shell} -n $out
        ## shellcheck
        ${shellcheck}/bin/shellcheck -e SC1117 -s bash -f tty $out
      '';
    };

  step = label: {
    command,
    withPkgs ? [],
    environment ? [],
    agents ? [],
    timeout ? 600,
    volumes ? [ "/var/lib/buildkite/nix:/nix" ],
    plugins ? [
      {
        "docker#v3.0.1" = {
          image = "nixpkgs/nix";
          mount-buildkite-agent = false;
          inherit environment volumes;
        };
      }
    ]
    }:
      {
        inherit label timeout plugins agents;
        command = writeStrictShellScript
         (toLower (
           replaceStrings [" "] ["-"] (
             replaceStrings [ ":" ] [""] (toString label)))) ''
               export PATH=${makeSearchPath "bin" withPkgs }:$PATH
               ${command}
             '';
      };

    steps = {
      populate_nix_cache = queue:
        step ":pipeline: Pre-populate Nix Store" {
          agents = [ "queue=${queue}" "nix=true" ];
          plugins = null;
          command = ''
            cp -pur /nix/* /nixstore/
          '';
        };
      wait = "wait";
    };

   pipeline = s:
     writeTextFile {
      name = "pipeline.json";
      text = builtins.toJSON (s);
     };


in

  {
    inherit pkgs lib pipeline step steps;
  }