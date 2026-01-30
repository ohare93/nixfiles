{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "zsh-ai-cmd";
  version = "unstable-2026-01-24";

  src = fetchFromGitHub {
    owner = "ohare93";
    repo = "zsh-ai-cmd";
    rev = "3ac65dcc93b287eddca3eff0715f68ed1fc2cdc6"; # main - claude-code provider
    hash = "sha256-8FpldqnLP5LkKYr6K1VY0uQ2eAYL27Myw7R3qrZUlOQ=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/zsh-ai-cmd
    cp -r . $out/share/zsh-ai-cmd/

    # Set claude-code as the default provider
    sed -i '1i\: "''${ZSH_AI_CMD_PROVIDER:=claude-code}"' $out/share/zsh-ai-cmd/zsh-ai-cmd.plugin.zsh

    runHook postInstall
  '';

  meta = with lib; {
    description = "Zsh plugin to convert natural language to shell commands using AI";
    homepage = "https://github.com/ohare93/zsh-ai-cmd";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
