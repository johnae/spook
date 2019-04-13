with import <nixpkgs> {};
with lib;

let

  step = label: {
    command,
    environment ? [],
    agents ? [],
    timeout ? 600
    }:
      {
        inherit label timeout agents command;
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