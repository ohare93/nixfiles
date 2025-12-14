{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./kanata.nix
  ];

  system.stateVersion = "25.05";

  # Add nixos-raspberrypi binary cache for cross-compilation
  nix.settings = {
    substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    # Allow jmo to use binary caches
    trusted-users = ["root" "jmo"];
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable ARM emulation for building RPi5 installer
  # boot.binfmt.emulatedSystems = ["aarch64-linux"];

  mynix = {
    podman.enable = true;
    displaylink.enable = true;
    hyprland-system.enable = true;
    battery-protection.enable = true; # Laptop dies at ~30% due to miscalibration
    agentic-coding.enable = true; # AI and agent development tools
  };

  hardware.bluetooth.enable = true;

  # udev rule for automatic monitor hotplug detection
  # Triggers hypr-display-switcher service when monitors are plugged/unplugged
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="drm", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="hypr-display-switcher.service"
  '';

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
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

  environment.systemPackages = with pkgs; [
    pcsclite
  ];

  qt = {
    enable = true;
    platformTheme = "kde";
    style = "adwaita-dark";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
