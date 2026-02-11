{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.mynix.niri-system;
in
  with lib; {
    imports = [
      inputs.niri.nixosModules.niri
    ];

    options.mynix = {
      niri-system = {
        enable = mkEnableOption "Niri system-level configuration";
      };
    };

    config = mkIf cfg.enable {
      # Enable Niri scrollable tiling window manager
      programs.niri.enable = true;

      # Udev rule to trigger display switcher on monitor hotplug
      # Uses a script to find graphical sessions and trigger the user service
      services.udev.extraRules = let
        hotplugHelper = pkgs.writeShellScript "niri-hotplug-helper" ''
          # Find all graphical sessions and trigger the display switcher for each
          for session in $(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
            session_type=$(${pkgs.systemd}/bin/loginctl show-session "$session" -p Type --value 2>/dev/null)
            if [ "$session_type" = "wayland" ] || [ "$session_type" = "x11" ]; then
              user=$(${pkgs.systemd}/bin/loginctl show-session "$session" -p Name --value 2>/dev/null)
              uid=$(${pkgs.coreutils}/bin/id -u "$user" 2>/dev/null)
              if [ -n "$uid" ]; then
                DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
                XDG_RUNTIME_DIR="/run/user/$uid" \
                ${pkgs.systemd}/bin/systemctl --user -M "$user@" start --no-block niri-display-switcher.service 2>/dev/null || true
              fi
            fi
          done
        '';
      in ''
        ACTION=="change", SUBSYSTEM=="drm", RUN+="${hotplugHelper}"
      '';


      # Use unstable niri for DisplayLink support (added in 25.11)
      programs.niri.package = pkgs.niri-unstable;

      # Display manager configuration (shared with Hyprland, use mkDefault to avoid conflicts)
      services.displayManager.sddm = {
        enable = mkDefault true;
        wayland.enable = mkDefault true;
      };

      # Enable gnome-keyring for password storage
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.sddm.enableGnomeKeyring = true;

      # PAM service for swaylock authentication
      security.pam.services.swaylock = {};

      # Polkit authentication agent for GUI password prompts
      environment.systemPackages = with pkgs; [
        polkit_gnome
      ];

      # File manager support services
      services.tumbler.enable = true;
      services.gvfs.enable = true;
    };
  }
