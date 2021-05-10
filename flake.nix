{
  description = "Spook - react to change";

  inputs = {
    nix-misc = {
      url = "github:johnae/nix-misc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-misc, nixpkgs }:
    let
      version = "0.9.7.${nixpkgs.lib.substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
      pkgs = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ nix-misc.overlay self.overlay ];
      });
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

      defaultPackage = forAllSystems (system: pkgs.${system}.spook);

      devShell = forAllSystems (system: pkgs.${system}.callPackage ./shell.nix {});

    };
}
