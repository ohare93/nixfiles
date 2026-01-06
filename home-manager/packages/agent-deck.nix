{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  tmux,
}:
buildGoModule {
  pname = "agent-deck";
  version = "0.8.20";

  src = fetchFromGitHub {
    owner = "asheshgoplani";
    repo = "agent-deck";
    rev = "v0.8.20"; # tags/v*
    hash = "sha256-uixAcmIQ9Tx+l3LhqG2XLQa8+v5Epj2IG5w5/iTOKoY=";
  };

  vendorHash = "sha256-X4n1zot+w6+2WGZmSrWaUnY9cp66G8H4MF70ZDgLD1E=";

  subPackages = ["cmd/agent-deck"];

  nativeBuildInputs = [makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/agent-deck \
      --prefix PATH : ${lib.makeBinPath [tmux]}
  '';

  doCheck = false;

  meta = with lib; {
    description = "Terminal session manager for AI coding agents";
    homepage = "https://github.com/asheshgoplani/agent-deck";
    mainProgram = "agent-deck";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
