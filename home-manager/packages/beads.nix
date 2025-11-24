{
  lib,
  buildGoModule,
  fetchFromGitHub,
  git,
  makeWrapper,
}:
buildGoModule rec {
  pname = "beads";
  version = "0.23.1";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = "sha256-ibWPzNGUMk9NueWVR4xNS108ES2w1ulWL2ARB75xEig=";
  };

  vendorHash = "sha256-eUwVXAe9d/e3OWEav61W8lI0bf/IIQYUol8QUiQiBbo=";

  # Build the CLI tool from cmd/bd
  subPackages = ["cmd/bd"];

  # Skip tests - they require git in PATH during build
  doCheck = false;

  # The binary is named 'bd', not 'beads'
  postInstall = ''
    # Binary is already installed as 'bd' due to subPackages
    # Wrap the binary to ensure git is available at runtime
    wrapProgram $out/bin/bd \
      --prefix PATH : ${lib.makeBinPath [git]}
  '';

  nativeBuildInputs = [makeWrapper];

  meta = with lib; {
    description = "Graph-based issue tracker and memory system for AI coding agents";
    homepage = "https://github.com/steveyegge/beads";
    mainProgram = "bd";
  };
}
