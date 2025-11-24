{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.waybar-updates;

  # Custom update checker script with NixOS paths
  update-checker = pkgs.writeShellScriptBin "nixos-update-checker" ''
    #!/usr/bin/env bash

    # ===== Configuration =====
    UPDATE_INTERVAL=3599  # Check interval in seconds (1 hour)
    NIXOS_CONFIG_PATH="~/nixfiles"  # Path to NixOS configuration
    CACHE_DIR="$HOME/.cache"
    STATE_FILE="$CACHE_DIR/nix-update-state"
    LAST_RUN_FILE="$CACHE_DIR/nix-update-last-run"
    LAST_RUN_TOOLTIP="$CACHE_DIR/nix-update-tooltip"
    BOOT_MARKER_FILE="$CACHE_DIR/nix-update-boot-marker"

    SKIP_AFTER_BOOT=true
    GRACE_PERIOD=60
    UPDATE_LOCK_FILE="false"

    # ===== Helper Functions =====
    function send_notification() {
        local title="$1"
        local message="$2"
        ${pkgs.libnotify}/bin/notify-send "$title" "$message" -e
    }

    function init_files() {
        mkdir -p "$CACHE_DIR"
        [ ! -f "$STATE_FILE" ] && echo "0" > "$STATE_FILE"
        [ ! -f "$LAST_RUN_FILE" ] && echo "0" > "$LAST_RUN_FILE"
        [ ! -f "$LAST_RUN_TOOLTIP" ] && echo "System updated" > "$LAST_RUN_TOOLTIP"
    }

    function check_boot_resume() {
        local current_time=$(date +%s)
        local uptime_seconds=$(cat /proc/uptime | awk '{print int($1)}')

        if [ ! -f "$BOOT_MARKER_FILE" ] || [ $uptime_seconds -lt "$GRACE_PERIOD" ]; then
            echo "$current_time" > "$BOOT_MARKER_FILE"
            return 0
        fi
        return 1
    }

    function check_network_connectivity() {
        ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1
    }

    function calc_next_update() {
        local last_run=$(cat "$LAST_RUN_FILE")
        local current_time=$(date +%s)
        local next_update=$((UPDATE_INTERVAL - (current_time - last_run)))
        local next_update_min=$((next_update / 60))
        echo "$next_update_min"
    }

    function var_setter() {
        local updates=$(cat "$STATE_FILE")
        if [ "$updates" -ne 0 ]; then
            alt="has-updates"
            tooltip=$(cat "$LAST_RUN_TOOLTIP")
        else
            alt="updated"
            tooltip="System updated"
        fi
    }

    function check_for_updates() {
        local tempdir=$(mktemp -d)
        trap "rm -rf '$tempdir'" EXIT

        send_notification "Checking for Updates" "Please be patient"

        # Copy flake files to temp directory
        cp -r "$NIXOS_CONFIG_PATH"/* "$tempdir"
        cd "$tempdir" || return 1

        # Update flake inputs
        if ! ${pkgs.nix}/bin/nix flake update 2>&1; then
            echo "Failed to update flake inputs" >&2
            send_notification "Update Check Failed" "Failed to update flake inputs"
            return 1
        fi

        # Build the updated system configuration
        local hostname=$(hostname)
        if ! ${pkgs.nix}/bin/nix build ".#nixosConfigurations.$hostname.config.system.build.toplevel" --no-link 2>&1; then
            echo "Failed to build system configuration for $hostname" >&2
            send_notification "Update Check Failed" "Failed to build system configuration"
            return 1
        fi

        # Check if result symlink exists
        if [ ! -e ./result ]; then
            # Try building with output link
            ${pkgs.nix}/bin/nix build ".#nixosConfigurations.$hostname.config.system.build.toplevel" 2>/dev/null
        fi

        if [ -e ./result ]; then
            # Compare with current system using nvd
            local updates=$(${pkgs.nvd}/bin/nvd diff /run/current-system ./result 2>/dev/null | grep -e '\[U' | wc -l)
            local tooltip=$(${pkgs.nvd}/bin/nvd diff /run/current-system ./result 2>/dev/null | grep -e '\[U' | awk '{ for (i=3; i<NF; i++) printf $i " "; if (NF >= 3) print $NF; }' ORS='\\n')

            echo "$updates" > "$STATE_FILE"
            echo "$(date +%s)" > "$LAST_RUN_FILE"

            if [ "$updates" -eq 0 ]; then
                echo "System updated" > "$LAST_RUN_TOOLTIP"
                send_notification "Update Check Complete" "No updates available"
            elif [ "$updates" -eq 1 ]; then
                echo "$tooltip" > "$LAST_RUN_TOOLTIP"
                send_notification "Update Check Complete" "Found 1 update"
            else
                echo "$tooltip" > "$LAST_RUN_TOOLTIP"
                send_notification "Update Check Complete" "Found $updates updates"
            fi
            return 0
        else
            send_notification "Update Check Failed" "Could not build system"
            return 1
        fi
    }

    function main() {
        init_files

        if [ "$SKIP_AFTER_BOOT" = "true" ] && check_boot_resume; then
            local updates=$(cat "$STATE_FILE")
            var_setter
            echo "{ \"text\":\"$updates\", \"alt\":\"$alt\", \"tooltip\":\"$tooltip\" }"
            exit 0
        fi

        if check_network_connectivity; then
            local updates=$(cat "$STATE_FILE")
            local last_run=$(cat "$LAST_RUN_FILE")
            local current_time=$(date +%s)

            if [ $((current_time - last_run)) -gt "$UPDATE_INTERVAL" ]; then
                if check_for_updates; then
                    updates=$(cat "$STATE_FILE")
                    var_setter
                else
                    updates=""
                    alt="error"
                    tooltip="Update check failed"
                fi
            else
                send_notification "Please Wait" "Next update is in $(calc_next_update) min."
                var_setter
            fi
        else
            local updates=$(cat "$STATE_FILE")
            var_setter
            send_notification "Update Check Failed" "Not connected to the internet"
        fi

        echo "{ \"text\":\"$updates\", \"alt\":\"$alt\", \"tooltip\":\"$tooltip\" }"
    }

    main
  '';
in
  with lib; {
    options.mynix = {
      waybar-updates = {
        enable = mkEnableOption "Waybar NixOS update notifications";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [
        update-checker
        pkgs.nvd
        pkgs.libnotify
      ];

      # Create waybar configuration snippet for updates
      home.file.".config/waybar/modules/nixos-updates.json".text = builtins.toJSON {
        "custom/nixos-updates" = {
          exec = "${update-checker}/bin/nixos-update-checker";
          signal = 12;
          interval = 3600;
          tooltip = true;
          return-type = "json";
          format = "󰚰 {}";
          on-click = "${update-checker}/bin/nixos-update-checker";
        };
      };
    };
  }
