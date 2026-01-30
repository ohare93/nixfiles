{ inputs, ... }:
{
  flake.aspects.hardware-skylight = {
    nixos = { ... }: {
      imports = [
        inputs.disko.nixosModules.disko
        (inputs.self + "/defs/hosts/skylight/disk-config.nix")
        inputs.agenix.nixosModules.default
      ];

      # Bootloader
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Enable ARM emulation for building RPi5 images
      boot.binfmt.emulatedSystems = ["aarch64-linux"];

      # Add swap for memory-intensive builds (qtwebengine under QEMU needs >10GB)
      swapDevices = [{
        device = "/swapfile";
        size = 16 * 1024; # 16GB
      }];

      # VirtIO kernel modules required for VM disk access in initramfs
      boot.initrd.availableKernelModules = [
        "virtio_blk"
        "virtio_pci"
        "virtio_ring"
      ];
    };
  };
}
