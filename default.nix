with import <nixpkgs> {};
stdenv.mkDerivation rec {
  name = "spook-${SPOOK_VERSION}";
  SPOOK_VERSION = "0.9.5";

  src = fetchurl {
    url = https://github.com/johnae/spook/archive/916d43da3071a1b29193f783c1fa0953f8b51970.tar.gz;
    sha256 = "05699c99c267970d25fcb2198cdd0fcb144da90651128b61e88881450c69c4d9";
  };

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