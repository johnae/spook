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

  agents = a: s:
    flatten (map (step:
      (unique (map (agents:
        (if isAttrs step then step // { inherit agents; }
        else step)
      ) a))
    ) s);

in

  {
    inherit pkgs lib step wait agents;
  }