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
          image = builtins.getEnv "NIXIMAGE";
          mount-buildkite-agent = false;
          entrypoint = "/usr/bin/bash";
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
               export PATH=${if length withPkgs > 0 then
               ''${makeSearchPath "bin" withPkgs }:$PATH''
               else
               ''$PATH''
               }
               ${command}
             '';
      };

   wait = "wait";

   pipeline = s:
     writeTextFile {
      name = "pipeline.json";
      text = builtins.toJSON (s);
     };


in

  {
    inherit pkgs lib pipeline step wait;
  }