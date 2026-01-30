# Hardware configuration for Raspberry Pi 5
# Minimal hardware config - SD image functionality provided by nixos-raspberrypi
{
  lib,
  ...
}: {
  imports = [];

  # Raspberry Pi 5 specific kernel modules
  boot.initrd.availableKernelModules = [
    "bcm2835_dma"
    "i2c_bcm2835"
  ];

  boot.initrd.kernelModules = [
    "vc4"
    "v3d"
  ];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # Filesystem configuration for SD card
  # Note: nix-anywhere will handle disk partitioning
  # These are the expected mount points after deployment

  # Boot firmware partition (FAT32)
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = ["nofail" "noauto"];
  };

  # Root filesystem (ext4)
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # Swap file (optional, but can help with memory-intensive tasks)
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB swap
    }
  ];

  # Platform configuration
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # WiFi firmware (important for RPi5 wireless)
  hardware.enableRedistributableFirmware = true;

  # Raspberry Pi 5 has BCM2712 SoC
  # The nixos-raspberrypi modules handle most hardware-specific configuration
}
