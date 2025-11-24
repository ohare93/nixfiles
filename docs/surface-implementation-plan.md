# Surface Go 2 NixOS Installation Implementation Plan

## Overview

Install NixOS on Surface Go 2 tablet with full hardware support including Type Cover keyboard, touchscreen, and WiFi.

## Prerequisites

### Hardware Requirements

- Surface Go 2 tablet
- USB-C hub with:
  - Ethernet port (WiFi firmware may not work during install)
  - USB port for installation media
- USB drive (8GB+) for installation media
- Access to another computer for:
  - Creating installation media
  - Optional: distributed builds during kernel compilation

### Pre-Installation Steps

1. **Backup any Windows data** if dual-booting or want to preserve
2. **Disable Secure Boot**:
   - Hold Volume Up while powering on to enter UEFI
   - Navigate to Security settings
   - Disable Secure Boot
   - Save and exit

## Installation Process

### Phase 1: Create Installation Media

1. Download NixOS ISO from https://nixos.org/download/
   - Use either minimal or graphical installer
2. Write to USB drive:
   ```bash
   dd if=nixos-*.iso of=/dev/sdX bs=4M status=progress
   ```

### Phase 2: Boot Installation Media

1. Connect USB hub with ethernet and installation USB
2. Hold Volume Down while powering on to boot from USB
3. Select USB drive from boot menu

### Phase 3: Initial System Setup

1. Connect to network:
   - Ethernet should work automatically via DHCP
   - If using graphical ISO with WiFi: use `nmtui` to connect
2. Partition disk (adjust sizes as needed):

   ```bash
   # List disks
   lsblk

   # Partition (assuming /dev/nvme0n1)
   parted /dev/nvme0n1 -- mklabel gpt
   parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/nvme0n1 -- set 1 esp on
   parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

   # Format partitions
   mkfs.fat -F 32 -n boot /dev/nvme0n1p1
   mkfs.ext4 -L nixos /dev/nvme0n1p2

   # Mount
   mount /dev/disk/by-label/nixos /mnt
   mkdir -p /mnt/boot
   mount /dev/disk/by-label/boot /mnt/boot
   ```

### Phase 4: Generate Initial Configuration

```bash
nixos-generate-config --root /mnt
```

### Phase 5: Configure NixOS with Surface Support

Edit `/mnt/etc/nixos/configuration.nix` to include basic settings, then create a flake-based configuration.

Create `/mnt/etc/nixos/flake.nix`:

```nix
{
  description = "Surface Go 2 NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-hardware }: {
    nixosConfigurations.surface-go2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Surface Go hardware profile
        nixos-hardware.nixosModules.microsoft-surface-go

        # Your hardware config
        ./hardware-configuration.nix

        # Main configuration
        ./configuration.nix
      ];
    };
  };
}
```

Update `/mnt/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "surface-go2";
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_DK.UTF-8";

  # User account
  users.users.yourname = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  # Desktop environment (choose one)
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # OR for a lighter option:
  # services.xserver.desktopManager.xfce.enable = true;

  # Enable touchscreen
  services.xserver.libinput.enable = true;

  # Essential packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    firefox
  ];

  # Enable SSH for remote access during long builds
  services.openssh.enable = true;

  # System state version
  system.stateVersion = "24.05";
}
```

### Phase 6: Install NixOS

```bash
nixos-install
```

**IMPORTANT**: The first installation will take a very long time (potentially hours) because it needs to compile the custom linux-surface kernel. This is normal.

### Phase 7: Post-Installation

1. Reboot:
   ```bash
   reboot
   ```
2. Remove installation media
3. Boot into NixOS
4. Log in with the user created during installation
5. Change initial password:
   ```bash
   passwd
   ```

## Optional: Distributed Builds Setup

To avoid slow kernel compilation on the Surface Go 2 itself, configure distributed builds to a more powerful machine.

On the Surface Go 2, add to `configuration.nix`:

```nix
{
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "builder.local";
      system = "x86_64-linux";
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }
  ];

  # Optional: use SSH keys for authentication
  programs.ssh.extraConfig = ''
    Host builder.local
      User builder
      IdentityFile /home/yourname/.ssh/builder_key
  '';
}
```

## Troubleshooting

### WiFi Not Working During Install

- Use USB ethernet adapter with hub
- WiFi will work after kernel is compiled and installed

### Kernel Build Taking Forever

- This is expected on first build (Surface Go 2 is slow)
- Set up distributed builds (see above)
- Or be patient and let it run overnight

### Type Cover Not Detected

- Ensure nixos-hardware module is properly loaded
- Check `dmesg` for hardware detection messages
- May need to reconnect Type Cover after boot

### Screen Rotation

GNOME handles this automatically. For other DEs:

```nix
services.xserver.displayManager.sessionCommands = ''
  ${pkgs.xorg.xrandr}/bin/xrandr --output DSI-1 --rotate normal
'';
```

## Post-Installation Tweaks

### Enable Fractional Scaling (GNOME)

```bash
gsettings set org.gnome.muttter experimental-features "['scale-monitor-framebuffer']"
```

### Power Management

The nixos-hardware module should handle this, but you can verify:

```nix
services.thermald.enable = true;
services.tlp.enable = true;
```

## References

- nixos-hardware Surface Go module: https://github.com/NixOS/nixos-hardware/tree/master/microsoft/surface
- linux-surface project: https://github.com/linux-surface/linux-surface
- Nathan Bijnens' Surface Go guide: https://nathan.gs/2024/02/06/installing-nixos-on-surface-go/
- NixOS Wiki Surface Go 2: https://wiki.nixos.org/wiki/Hardware/Microsoft/Surface_Go_2

## Success Criteria

- [ ] System boots without installation media
- [ ] Type Cover keyboard is functional
- [ ] Touchscreen works
- [ ] WiFi connects successfully
- [ ] Desktop environment loads
- [ ] Battery/power management operational
