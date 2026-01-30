{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.hyprland-system;
in
  with lib; {
    options.mynix = {
      hyprland-system = {
        enable = mkEnableOption "Hyprland system-level configuration";
      };
    };

    config = mkIf cfg.enable {
      # Enable Hyprland tiling window manager
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # Display manager configuration
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      # Enable gnome-keyring for password storage
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.sddm.enableGnomeKeyring = true;

      # CRITICAL: PAM service for hyprlock authentication with PIN support
      security.pam.services.hyprlock = {
        # Allow PIN-based unlock: tries PIN first, falls back to password
        text = lib.mkDefault ''
          # Try PIN authentication first (if PIN file exists)
          auth sufficient pam_exec.so quiet ${pkgs.writeShellScript "hyprlock-pin-auth" ''
            PIN_FILE="''${XDG_RUNTIME_DIR}/hyprlock-pin"

            # If no PIN file exists, fail and fall through to password auth
            if [ ! -f "$PIN_FILE" ]; then
              exit 1
            fi

            # Read the PIN from file (hashed with SHA-256)
            STORED_PIN=$(cat "$PIN_FILE")

            # Read password input from PAM (passed via stdin)
            read -r INPUT_PIN

            # Hash the input
            INPUT_HASH=$(echo -n "$INPUT_PIN" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)

            # Compare hashes
            if [ "$INPUT_HASH" = "$STORED_PIN" ]; then
              exit 0  # Success - PIN matches
            else
              exit 1  # Fail - try password auth
            fi
          ''}

          # Fall back to standard password authentication
          auth include login
        '';
      };

      # Polkit authentication agent for GUI password prompts
      environment.systemPackages = with pkgs; [
        polkit_gnome

        # PIN management script for hyprlock
        (writeShellScriptBin "hyprlock-set-pin" ''
          #!/usr/bin/env bash

          PIN_FILE="''${XDG_RUNTIME_DIR}/hyprlock-pin"

          echo "=== Hyprlock PIN Setup ==="
          echo ""
          echo "This will set a PIN for unlocking your screen with hyprlock."
          echo "Your full password will still work as a fallback."
          echo ""

          # Get PIN with confirmation
          read -s -p "Enter your desired PIN: " PIN1
          echo ""
          read -s -p "Confirm your PIN: " PIN2
          echo ""

          if [ "$PIN1" != "$PIN2" ]; then
            echo "❌ PINs don't match. Please try again."
            exit 1
          fi

          if [ -z "$PIN1" ]; then
            echo "❌ PIN cannot be empty."
            exit 1
          fi

          # Hash the PIN with SHA-256
          PIN_HASH=$(echo -n "$PIN1" | ${coreutils}/bin/sha256sum | ${coreutils}/bin/cut -d' ' -f1)

          # Save to file
          echo "$PIN_HASH" > "$PIN_FILE"
          chmod 600 "$PIN_FILE"

          echo "✓ PIN set successfully!"
          echo ""
          echo "You can now use your PIN to unlock hyprlock."
          echo "To remove the PIN, run: hyprlock-remove-pin"
        '')

        (writeShellScriptBin "hyprlock-remove-pin" ''
          #!/usr/bin/env bash

          PIN_FILE="''${XDG_RUNTIME_DIR}/hyprlock-pin"

          if [ -f "$PIN_FILE" ]; then
            rm "$PIN_FILE"
            echo "✓ PIN removed. You'll now use your full password for hyprlock."
          else
            echo "No PIN is currently set."
          fi
        '')
      ];

      # File manager support services
      services.tumbler.enable = true; # Thumbnail generation for Thunar
      services.gvfs.enable = true; # Mount, trash, and other functionalities
    };
  }
