{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./sd-card-optimization.nix
    # Raspberry Pi 5 hardware modules
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
    # SD image builder from nixos-raspberrypi (compatible with RPi bootloader)
    inputs.nixos-raspberrypi.nixosModules.sd-image
  ];

  # Hostname
  networking.hostName = "rectangle";

  # Raspberry Pi kernel bootloader (stores generations on disk, auto-boots to current)
  # Note: No interactive menu - manual rollback requires editing /boot/firmware/config.txt
  boot.loader.raspberryPi.bootloader = "kernel";
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce false;

  # Fix DRM race condition: disable simpledrm modeset so vc4 can claim display
  boot.kernelParams = ["simpledrm.modeset=0"];

  # Enable NetworkManager for WiFi
  networking.networkmanager.enable = true;

  # Ensure wireless support is enabled
  networking.wireless.enable = lib.mkForce false; # NetworkManager handles this

  # X11 with minimal window manager
  services.xserver = {
    enable = true;

    # Danish keyboard layout
    xkb = {
      layout = "dk";
      variant = "";
    };

    # Use fbdev driver for Raspberry Pi 5 framebuffer
    videoDrivers = ["fbdev"];

    windowManager.i3.enable = true;
    displayManager.lightdm.enable = true;
  };

  # Auto-login to get to desktop quickly
  services.displayManager.autoLogin = {
    enable = true;
    user = "jmo";
  };

  # Audio with pipewire (crucial for both Moonlight and Jellyfin)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # 32-bit support is not available on aarch64
    alsa.support32Bit = false;
    pulse.enable = true;
    # Enable JACK support for low-latency audio if needed
    jack.enable = true;
  };

  # Enable OpenSSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Enable XRDP for remote desktop access via Remmina
  services.xrdp = {
    enable = true;
    defaultWindowManager = "i3";
    openFirewall = true;
  };

  # Enable console login on tty1 with auto-login
  services.getty = {
    autologinUser = "jmo";
    helpLine = "Rectangle - Raspberry Pi 5 Streaming Client";
  };

  # Streaming and media packages
  environment.systemPackages = with pkgs; [
    # Game streaming client
    moonlight-qt

    # Movie/media streaming client
    jellyfin-media-player

    # Web browser
    chromium

    # Terminal emulator for i3
    alacritty

    # Application launcher for i3
    dmenu

    # Useful debugging tools
    pciutils
    usbutils
    htop
  ];

  # GnuPG with SSH support
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # User configuration
  users.users.jmo = {
    isNormalUser = true;
    description = inputs.private.identity.fullName;
    extraGroups = ["wheel" "networkmanager" "audio" "video"];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here after first boot
    ];
  };

  # Sudo without password for wheel group
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Enable firmware updates
  hardware.enableRedistributableFirmware = true;

  # Bluetooth support (for Xbox controller and other accessories)
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Xbox controller support via Bluetooth
  hardware.xpadneo.enable = true;

  # OpenGL support for graphics (important for video playback and streaming)
  hardware.graphics = {
    enable = true;
    # 32-bit support is not available on aarch64
  };

  # Disable features that aren't available on aarch64
  home-manager.users.jmo = {
    # Enable i3 window manager with Rofi and Polybar
    mynix.i3.enable = true;

    # Disable Elm (broken on aarch64)
    mynix.elm.enable = lib.mkForce false;

    # Disable Gren (broken Haskell dependencies on aarch64)
    mynix.terminal-misc.gren.enable = lib.mkForce false;

    programs.nvf.settings.vim = {
      # Disable formatters
      languages = {
        markdown.format.enable = lib.mkForce false;
        css.format.enable = lib.mkForce false;
        ts.format.enable = lib.mkForce false;
      };

      # Disable AI assistant plugins
      assistant.codecompanion-nvim.enable = lib.mkForce false;

      # Disable Gren treesitter grammar (has broken Haskell dependencies on aarch64)
      treesitter.grammars = lib.mkForce [
        pkgs.tree-sitter-grammars.tree-sitter-norg
        pkgs.tree-sitter-grammars.tree-sitter-norg-meta
      ];
    };
  };

  # System state version
  system.stateVersion = "25.05";
}
