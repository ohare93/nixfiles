{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcptools";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "f";
    repo = "mcptools";
    rev = "v${version}";
    hash = "sha256-UFK57MzsxoLdtdFhhQ+x57LomyOBijxyHkOCgj6NuJI=";
  };

  vendorHash = "sha256-tHMBwYZUrcohUEpIXgbhSCkxRi+/GxnPtEX4Uj5rwjo=";

  doCheck = false;

  meta = with lib; {
    description = "CLI tool for interacting with MCP servers from the shell";
    homepage = "https://github.com/f/mcptools";
    license = licenses.mit;
    mainProgram = "mcptools";
    platforms = platforms.linux;
  };
}
