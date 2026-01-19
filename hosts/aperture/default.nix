{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    # Surface Go 2 hardware support (custom kernel, touchscreen, Type Cover, etc.)
    inputs.nixos-hardware.nixosModules.microsoft-surface-go
  ];

  system.stateVersion = "25.05";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable custom modules
  mynix = {
    battery-protection.enable = true; # Optimize battery health for tablet
    uinput.enable = true; # Required for espanso
  };

  # Disable power-profiles-daemon (conflicts with TLP from battery-protection)
  # nixos-hardware Surface module enables this by default
  services.power-profiles-daemon.enable = lib.mkForce false;

  # Bluetooth for accessories
  hardware.bluetooth.enable = true;

  # X11 and desktop environment
  services.xserver.enable = true;

  # Plasma/KDE desktop environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Touchscreen and trackpad support
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  # Printing support
  services.printing.enable = true;

  # Audio with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Sudo configuration with password exemptions for common NixOS commands
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true; # Keep password requirement for general sudo
    extraRules = [
      {
        users = ["jmo"];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild *";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/nix-collect-garbage *";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/systemctl *";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };

  # Surface-specific packages
  environment.systemPackages = with pkgs; [
    # Useful for debugging hardware
    pciutils
    usbutils
  ];

  # Qt theming for Plasma
  qt = {
    enable = true;
    platformTheme = "kde";
  };

  # GnuPG with SSH support
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
