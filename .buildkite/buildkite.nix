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

in

  {
    inherit pkgs lib step wait;
  }