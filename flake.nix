{
  description = "Spook - react to change";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixkite = {
      url = "github:johnae/nixkite/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nix-misc = {
      url = "github:johnae/nix-misc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, nixkite, nix-misc, nixpkgs }:
    let
      genAttrs' = values: f: builtins.listToAttrs (map f values);
      version = "0.9.7.${nixpkgs.lib.substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
    in
    {

      overlay = final: prev: {
        spook = final.stdenv.mkDerivation {
          inherit version;
          name = "spook-${version}";
          SPOOK_VERSION = version;

          src = self;

          LUAJIT_SRC = final.luajit_2_1.src;
          LUAJIT_INCLUDE = "${final.luajit_2_1}/include/luajit-2.1";
          LUAJIT_ARCHIVE = "${final.luajit_2_1}/lib/libluajit-5.1.a";
          LUAJIT = "${final.luajit_2_1}/bin/luajit";

          installPhase = ''
            mkdir -p $out/bin
            make install PREFIX=$out
          '';
        };
      };

    } // flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ nix-misc.overlay ];
          };
        in
        {
          defaultPackage =
            (import nixpkgs {
              inherit system;
              overlays = [ self.overlay nix-misc.overlay ];
            }).spook;

          devShell = import ./shell.nix { nixpkgs = pkgs; };

          packages = pkgs // {
            buildkite =
              let
                pipelineDir = ./.buildkite;
                fullPath = name: pipelineDir + "/${name}";
                pipelinePaths = map fullPath (builtins.attrNames (builtins.readDir pipelineDir));
              in
              genAttrs' pipelinePaths (path: {
                name = nixpkgs.lib.removeSuffix ".nix" (builtins.baseNameOf path);
                value = import nixkite {
                  inherit pkgs;
                  pipeline = path;
                };
              });
          };
        }
      );
}
