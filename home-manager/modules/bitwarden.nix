{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.mynix.bitwarden;

  # Rofi-based Bitwarden password picker script
  rofi-bw = pkgs.writeShellScriptBin "rofi-bw" ''
    set -euo pipefail

    BW="${pkgs.bitwarden-cli}/bin/bw"
    ROFI="${pkgs.rofi}/bin/rofi"
    JQ="${pkgs.jq}/bin/jq"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    CLIP="${pkgs.wl-clipboard}/bin/wl-copy"

    SESSION_FILE="$HOME/.cache/bw-session"

    # Check vault status
    get_status() {
      $BW status 2>/dev/null | $JQ -r '.status' 2>/dev/null || echo "unauthenticated"
    }

    # Get or create session
    get_session() {
      local status=$(get_status)

      case "$status" in
        "unauthenticated")
          # Need to login
          local password=$($ROFI -dmenu -password -p "Bitwarden Master Password" -lines 0)
          if [ -z "$password" ]; then
            exit 1
          fi
          session=$($BW login --raw <<< "$password" 2>/dev/null) || {
            $NOTIFY -u critical "Bitwarden" "Login failed"
            exit 1
          }
          echo "$session" > "$SESSION_FILE"
          chmod 600 "$SESSION_FILE"
          echo "$session"
          ;;
        "locked")
          # Need to unlock
          local password=$($ROFI -dmenu -password -p "Unlock Bitwarden" -lines 0)
          if [ -z "$password" ]; then
            exit 1
          fi
          session=$($BW unlock --raw <<< "$password" 2>/dev/null) || {
            $NOTIFY -u critical "Bitwarden" "Unlock failed"
            exit 1
          }
          echo "$session" > "$SESSION_FILE"
          chmod 600 "$SESSION_FILE"
          echo "$session"
          ;;
        "unlocked")
          # Already unlocked, get session from cache
          if [ -f "$SESSION_FILE" ]; then
            cat "$SESSION_FILE"
          else
            # Session file missing but vault unlocked - need to re-unlock
            local password=$($ROFI -dmenu -password -p "Unlock Bitwarden" -lines 0)
            if [ -z "$password" ]; then
              exit 1
            fi
            session=$($BW unlock --raw <<< "$password" 2>/dev/null) || {
              $NOTIFY -u critical "Bitwarden" "Unlock failed"
              exit 1
            }
            echo "$session" > "$SESSION_FILE"
            chmod 600 "$SESSION_FILE"
            echo "$session"
          fi
          ;;
      esac
    }

    # Main function
    main() {
      local session=$(get_session)
      export BW_SESSION="$session"

      # Sync vault (quick, ensures fresh data)
      $BW sync >/dev/null 2>&1 || true

      # Get all login items
      local items=$($BW list items 2>/dev/null | $JQ -r '.[] | select(.type == 1) | "\(.name) [\(.login.username // "no username")]|\(.id)"')

      if [ -z "$items" ]; then
        $NOTIFY "Bitwarden" "No items found"
        exit 0
      fi

      # Show items in rofi (display name, pass id)
      local selected=$(echo "$items" | cut -d'|' -f1 | $ROFI -dmenu -i -p "Bitwarden" -format 'i')

      if [ -z "$selected" ]; then
        exit 0
      fi

      # Get the selected item's ID
      local item_id=$(echo "$items" | sed -n "$((selected + 1))p" | cut -d'|' -f2)

      # Show action menu
      local action=$($ROFI -dmenu -p "Action" << EOF
Copy Password
Copy Username
Copy TOTP
Type Password
Type Username
EOF
      )

      case "$action" in
        "Copy Password")
          local password=$($BW get password "$item_id" 2>/dev/null)
          echo -n "$password" | $CLIP
          $NOTIFY "Bitwarden" "Password copied to clipboard"
          ;;
        "Copy Username")
          local username=$($BW get username "$item_id" 2>/dev/null)
          echo -n "$username" | $CLIP
          $NOTIFY "Bitwarden" "Username copied to clipboard"
          ;;
        "Copy TOTP")
          local totp=$($BW get totp "$item_id" 2>/dev/null) || {
            $NOTIFY -u critical "Bitwarden" "No TOTP configured for this item"
            exit 1
          }
          echo -n "$totp" | $CLIP
          $NOTIFY "Bitwarden" "TOTP copied to clipboard"
          ;;
        "Type Password")
          local password=$($BW get password "$item_id" 2>/dev/null)
          sleep 0.5
          ${pkgs.wtype}/bin/wtype "$password"
          ;;
        "Type Username")
          local username=$($BW get username "$item_id" 2>/dev/null)
          sleep 0.5
          ${pkgs.wtype}/bin/wtype "$username"
          ;;
      esac
    }

    main "$@"
  '';
in
  with lib; {
    options.mynix = {
      bitwarden = {
        enable = mkEnableOption "Bitwarden CLI for password management";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.bitwarden-cli
        pkgs.jq
        pkgs.wtype # For typing passwords directly
        rofi-bw
      ];

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
