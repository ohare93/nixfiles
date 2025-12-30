{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  tmux,
}:
buildGoModule rec {
  pname = "agent-deck";
  version = "0.8.4";

  src = fetchFromGitHub {
    owner = "asheshgoplani";
    repo = "agent-deck";
    rev = "v${version}";
    hash = "sha256-iLSsaGaN8TcDIkz9LDeqzz4rq6FIz/cDmgfz7KeRpbA=";
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
