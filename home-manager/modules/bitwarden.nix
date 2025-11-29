{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.mynix.bitwarden;
in
  with lib; {
    options.mynix = {
      bitwarden = {
        enable = mkEnableOption "Bitwarden CLI for password management";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.bitwarden-cli];

      # Configure the self-hosted server URL at activation time
      home.activation.bitwardenConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
        BW_CONFIG_DIR="$HOME/.config/Bitwarden CLI"
        mkdir -p "$BW_CONFIG_DIR"

        # Only configure if not already set or if server URL changed
        CONFIG_FILE="$BW_CONFIG_DIR/data.json"
        SERVER_URL="${inputs.private.services.bitwarden}"

        if [ ! -f "$CONFIG_FILE" ]; then
          # Create initial config with server URL
          echo '{}' > "$CONFIG_FILE"
          chmod 600 "$CONFIG_FILE"
        fi

        # Use bw config to set the server URL
        ${pkgs.bitwarden-cli}/bin/bw config server "$SERVER_URL" 2>/dev/null || true
      '';
    };
  }
