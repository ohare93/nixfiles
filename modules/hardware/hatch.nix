{ inputs, ... }:
{
  flake.aspects.hardware-hatch = {
    nixos = { ... }: {
      imports = [
        (inputs.self + "/defs/hosts/hatch/hardware-configuration.nix")
      ];

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      hardware.bluetooth.enable = true;
    };
  };
}
