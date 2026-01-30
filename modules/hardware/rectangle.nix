{ inputs, lib, ... }:
{
  flake.aspects.hardware-rectangle = {
    nixos = { pkgs, ... }: {
      imports = [
        (inputs.self + "/defs/hosts/rectangle/hardware-configuration.nix")
        (inputs.self + "/defs/hosts/rectangle/sd-card-optimization.nix")
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
        inputs.nixos-raspberrypi.nixosModules.sd-image
      ];

      # Raspberry Pi kernel bootloader (stores generations on disk, auto-boots to current)
      # Note: No interactive menu - manual rollback requires editing /boot/firmware/config.txt
      boot.loader.raspberryPi.bootloader = "kernel";
      boot.loader.generic-extlinux-compatible.enable = lib.mkForce false;

      # Fix DRM race condition: disable simpledrm modeset so vc4 can claim display
      # consoleblank=0 prevents kernel console from blanking
      boot.kernelParams = ["simpledrm.modeset=0" "consoleblank=0"];

      # Enable firmware updates
      hardware.enableRedistributableFirmware = true;

      # Bluetooth support (for Xbox controller and other accessories)
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;

      # Xbox controller support via Bluetooth
      hardware.xpadneo.enable = true;

      # OpenGL and hardware video decode support
      hardware.graphics = {
        enable = true;
        # 32-bit support is not available on aarch64

        # Enable VAAPI drivers for hardware video decoding
        extraPackages = with pkgs; [
          libva
          mesa
        ];
      };
    };
  };
}
