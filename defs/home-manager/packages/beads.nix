{
  lib,
  buildGoModule,
  fetchFromGitHub,
  git,
  makeWrapper,
}:
buildGoModule {
  pname = "beads";
  version = "0.46.0";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v0.46.0"; # tags/v*
    hash = "sha256-PMzLKb0pYKiXdiEXBFe6N4FZ3AaNfvBRZlQBKijtldc=";
  };

  vendorHash = "sha256-BpACCjVk0V5oQ5YyZRv9wC/RfHw4iikc2yrejZzD1YU=";

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
