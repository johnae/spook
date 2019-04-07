with import <nixpkgs> {};

stdenv.mkDerivation rec {
  version = "0.9.7-pre";
  name = "spook-${version}";
  SPOOK_VERSION = version;

  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    make install PREFIX=$out
    runHook postInstall
  '';

  buildInputs = [ gnumake gcc wget perl cacert ];

  meta = {
    description = "Lightweight evented utility for monitoring file changes and more";
    homepage = https://github.com/johnae/spook;
    license = "MIT";
  };

}
