{
  lib,
  writeShellApplication,
}:
writeShellApplication {
  name = "jjw";

  text = ''
    set -euo pipefail

    jjw_bin="''${JJW_BIN:-$HOME/.local/bin/jjw}"
    if [ ! -x "$jjw_bin" ]; then
      echo "jjw wrapper: expected executable at $jjw_bin" >&2
      echo "Install/update with: devbox run install-local (in ~/Development/active/tools/jj-workspace-helper)" >&2
      exit 127
    fi

    exec "$jjw_bin" "$@"
  '';

  meta = with lib; {
    description = "Shell wrapper for local jj-workspace-helper binary";
    mainProgram = "jjw";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
