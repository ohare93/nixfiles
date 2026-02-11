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
