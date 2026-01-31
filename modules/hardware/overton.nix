{inputs, ...}: {
  flake.aspects."overton.hardware" = {
    nixos = { ... }: {
      imports = [
        (inputs.self + "/defs/hosts/overton/hardware-configuration.nix")
      ];

      swapDevices = [{
        device = "/swapfile";
        size = 10 * 1024; # 10GB
      }];

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      hardware.bluetooth.enable = true;
    };
  };
}
