{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    inputs.agenix.nixosModules.default
  ];

  system.stateVersion = "25.05";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable ARM emulation for building RPi5 images
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # VirtIO kernel modules required for VM disk access in initramfs
  boot.initrd.availableKernelModules = [
    "virtio_blk"
    "virtio_pci"
    "virtio_ring"
  ];

  # Binary cache for nixos-raspberrypi
  nix.settings = {
    substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    # Allow jmo to use binary caches and be trusted for remote builds
    trusted-users = ["root" "jmo"];
  };

  # SSH for remote access and remote builds
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # User configuration
  users.users.jmo = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable sudo
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdg83O1jDEsYgBAvjJCYwC1KQhzYW32gG4Tap85JtbZ4R85AWXnUu/VjkGJ15sRGkaPmhdGmplTRasISLHz6lb6g4EXOw3A39r84Ujz+G/iLnZ6eqoXbCE7NqBSe0YEohtiucULJFdutsxzOnQljZYn41smxpkIoJMpjzk5HnP1WZWQFv/jNivr9W8B2TXBycKghZ25+8Hd+1nxh9X5NcwlZ4mSJtsfILV6ed2GfvLi7Fs2ecB/zaojktV1yXvFJX2pEWU0DfheJlcSSkAqXkDl/902TtU2efeyPFfTkWH9vQSdJ80pBkZ+TmxvokxxJOUEnnyd10e/OUW9gPs/XIegwtg8/z/2NR7j+1eDgZ6sUjDQop8j+L5lIk8KHbxzVfX4Ru1lCj+Lmy6N+NNdk788CMZTaqUiO75kjQcqg5sBUQBuL973dKfZ1ySOx/sMeQKiPxehaIk8nWpgPOjzOM5IfEU3Vs4btQnz7+WM2EcyzQ1SFGppXTGJyuA60oxzagGSn06eD6wIehmZBsxRyZBAunpGS+8Zybx57eBoLRAFLi4CEOixGUEbX32sGTuRXrqdIRDdzgv78wQCA9/6s+TvWjIVV0OuJhb0zfggQFfAZrfhmOfajFSX0jCDUR8jUSqJz+CxlbTJ8iwO1pdnGifX/PLz6RP3azt0yUgRn4lyw== jmo@overton"
    ];
  };

  # Allow wheel group to use sudo without password
  security.sudo.wheelNeedsPassword = false;

  # Disable SMART monitoring - doesn't work with VirtIO disks
  services.smartd.enable = lib.mkForce false;

  # Headless VM - no desktop environment needed
  # Just SSH + terminal for build machine use

  # Set hostname
  networking.hostName = "skylight";

  # Basic tools for a build/test VM
  environment.systemPackages = with pkgs; [
    git
    htop
    tmux
    neofetch
  ];

  mynix = {
    # Enable any common modules you want on the VM
    # This VM is primarily a headless build machine
  };
}
