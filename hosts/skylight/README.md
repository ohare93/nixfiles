# Skylight VM - NixOS Installation Guide

Quick reference for installing NixOS on VMs (tested on Unraid with VirtIO).

## VM Prerequisites

- VM with VirtIO disk controller (best performance for VMs)
- 100GB disk minimum
- Boot from NixOS ISO
- Network access for downloading packages

## Critical Configuration

### VirtIO Kernel Modules Required

**Must include in `default.nix`:**

```nix
boot.initrd.availableKernelModules = [
  "virtio_blk"  # VirtIO block device support
  "virtio_pci"  # VirtIO PCI bus
  "virtio_ring" # VirtIO ring buffer
];
```

**Why:** Without these modules in initramfs, the kernel cannot see VirtIO disks during boot. System will fail with "Can't lookup blockdev" errors.

## Installation Steps

### 1. Boot NixOS Live ISO

```bash

sudo -i

loadkeys dk

# Set password so ssh can be done
passwd

```

### 1.5 Ssh in

```bash

# Clear out the .ssh/known_hosts entries, if need be

ssh-copy-id -o PubkeyAuthentication=no root@<VM_IP>

ssh root@<VM_IP>

```

### 2. Get Configuration Files

```bash
# From build machine (overton):
rsync -avz --delete /home/jmo/nixfiles/ root@<VM_IP>:/tmp/nixfiles/

# On VM, trust the git repo:
git config --global --add safe.directory /tmp/nixfiles
```

### 3. Partition with Disko

```bash
cd /tmp/nixfiles
nix --extra-experimental-features "flakes nix-command" \
  run github:nix-community/disko/latest -- \
  --mode disko hosts/skylight/disk-config.nix
```

**Disko config creates:**

- `/dev/vda1`: 500MB ESP (vfat) mounted at `/boot`
- `/dev/vda2`: Remaining space (ext4) mounted at `/`

### 4. Install NixOS

```bash
cd /tmp/nixfiles
nixos-install --flake .#skylight --no-root-passwd
```

### 5. Reboot

Remove or deprioritize the ISO in Unraid VM settings, then reboot.

## Post-Installation

### First Login

```bash
# SSH with key authentication (configured in default.nix)
ssh jmo@<VM_IP>

# Passwordless sudo should work
sudo whoami  # Should not prompt for password
```

### Apply Configuration Updates

**From build machine (overton):**

```bash
# Update NixOS system configuration
nixos-rebuild switch \
  --flake /home/jmo/nixfiles#skylight \
  --target-host root@<VM_IP> \
  --use-remote-sudo

# Update home-manager configuration
home-manager switch --flake /home/jmo/nixfiles#jmo@skylight
```

## Configuration Files

- `default.nix` - Main NixOS system configuration
- `disk-config.nix` - Disko partition layout
- `hardware-configuration.nix` - (Optional) Hardware-specific settings

## Troubleshooting

### Boot fails with "Can't lookup blockdev"

**Problem:** VirtIO kernel modules not in initramfs

**Solution:** Add `boot.initrd.availableKernelModules = ["virtio_blk" "virtio_pci" "virtio_ring"]` to `default.nix`

### User has no sudo access

**Problem:** User not in wheel group or sudo requires password

**Solution:** Ensure in `default.nix`:

```nix
users.users.jmo = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];
};
security.sudo.wheelNeedsPassword = false;
```

### Hostname not showing in prompt

**Problem:** Starship hostname module disabled

**Solution:** In `home-manager/modules/starship.nix`:

```nix
hostname = {
  ssh_only = false;
  disabled = false;
};
```

## Key Learnings

- **VirtIO modules are mandatory** for VirtIO disk VMs - UUIDs and partlabels aren't available in initramfs without them
- **Direct device paths** (`/dev/vda1`, `/dev/vda2`) work reliably for VMs with fixed disk assignments
- **Disko handles** partitioning, formatting, and generating `fileSystems` config automatically
- **nixos-install** defaults to `/mnt` as the installation root (where disko mounts)
