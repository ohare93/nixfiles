{ inputs, ... }:
{
  flake.aspects."aperture.hardware" = {
    nixos = { ... }: {
      imports = [
        (inputs.self + "/defs/hosts/aperture/hardware-configuration.nix")
        inputs.nixos-hardware.nixosModules.microsoft-surface-go
      ];

      # Bootloader
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Bluetooth for accessories
      hardware.bluetooth.enable = true;
    };
  };
}
