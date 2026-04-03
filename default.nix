{ lib, stdenvNoCC, makeWrapper, age, fzf, gum, gh, jq }:

stdenvNoCC.mkDerivation rec {
  pname = "envoy";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -Dm755 ev.sh $out/bin/ev
    mkdir -p $out/lib/envoy
    cp lib/*.sh $out/lib/envoy/
  '';

  postFixup = ''
    wrapProgram $out/bin/ev \
      --set ENVOY_LIB "$out/lib/envoy" \
      --prefix PATH : ${lib.makeBinPath [ age fzf gum gh jq ]}
  '';

  meta = with lib; {
    description = "Encrypted .env vault manager with age encryption and git-backed storage";
    homepage = "https://github.com/AThevon/envoy";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "ev";
  };
}
