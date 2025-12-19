{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "zsh-ai-cmd";
  version = "unstable-2025-12-19";

  src = fetchFromGitHub {
    owner = "kylesnowschwartz";
    repo = "zsh-ai-cmd";
    rev = "a49933bb38c7fb50f0a5c665b4e934035bc55aec";
    hash = lib.fakeHash;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/zsh-ai-cmd
    cp -r . $out/share/zsh-ai-cmd/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Zsh plugin to convert natural language to shell commands using AI";
    homepage = "https://github.com/kylesnowschwartz/zsh-ai-cmd";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
