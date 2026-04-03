{ lib, stdenvNoCC, makeWrapper, age, fzf, gum, gh, jq }:

stdenvNoCC.mkDerivation rec {
  pname = "envora";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -Dm755 ev.sh $out/bin/ev
    mkdir -p $out/lib/envora
    cp lib/*.sh $out/lib/envora/
  '';

  postFixup = ''
    wrapProgram $out/bin/ev \
      --set ENVORA_LIB "$out/lib/envora" \
      --prefix PATH : ${lib.makeBinPath [ age fzf gum gh jq ]}
  '';

  meta = with lib; {
    description = "Encrypted .env vault manager with age encryption and git-backed storage";
    homepage = "https://github.com/AThevon/envora";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "ev";
  };
}
