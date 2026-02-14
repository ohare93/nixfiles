# NixOS Configuration Quick Reference

Personal quick reference for common commands and debugging.

## Repository Layout

This repo is now organized using Dendritic-style flake-parts modules.

```
modules/        # Flake-parts modules + aspects (composition)
defs/           # Module definitions + host assets (hardware-configuration, kanata, etc.)
overlays/       # Nix overlays
secrets/        # agenix-encrypted secrets
```

## Private Configuration Setup

This repo uses a separate private flake (`nixfiles.private`) to keep personal details (domains, IDs, emails, SSH info, Syncthing devices) out of the public repo while still allowing pure Nix evaluation and version-controlled configuration. See [docs/private-config.md](docs/private-config.md) for setup and usage.

## System Management

### Building and Updating

```bash
# Test configuration without switching (safe)
sudo nixos-rebuild test --flake .#overton

# Apply configuration and switch
sudo nixos-rebuild switch --flake .#overton

# Update all flake inputs
nix flake update

# Check what changed between current and new system
nix build ".#nixosConfigurations.overton.config.system.build.toplevel" -o result-new
nvd diff /run/current-system ./result-new

# Garbage collect old generations
sudo nix-collect-garbage -d
```

## SSH Keys and CA

### Naming conventions

- Host keys: `~/.ssh/host_<hostname>`
- Service keys: `~/.ssh/svc_<service>`
- Agenix keys: `~/.ssh/age_<hostname>`

### Agenix CLI default identity

The `agenix` wrapper defaults to `~/.ssh/age_<hostname>` if `-i/--identity` is not provided.

Override per-command:

```bash
agenix -i ~/.ssh/age_overton -e secrets/example.age
```

Override via env:

```bash
AGENIX_IDENTITY=~/.ssh/age_overton agenix -e secrets/example.age
```

### User CA

CA private key lives on Overton:

```bash
ssh-keygen -t ed25519 -f "$HOME/.ssh/ca/ssh_user_ca" -C "jmo-ssh-user-ca"
```

Sign a device key for 30 days:

```bash
ssh-keygen -s "$HOME/.ssh/ca/ssh_user_ca" \
  -I "<host>-$(date +%Y%m%d)" \
  -n "jmo" \
  -V +30d \
  "$HOME/.ssh/host_<hostname>.pub"
```

This writes `~/.ssh/host_<hostname>-cert.pub` alongside the public key and OpenSSH will pick it up automatically.

### Server trust (NixOS)

Set CA trust on servers you control:

```nix
mynix.ssh.ca = {
  enable = true;
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAGMME41mVJTB8zrubSIJcsYV2KGXc9FHguwULRd4f1 jmo-ssh-user-ca";
  authorizedPrincipalsFile = "/etc/ssh/auth_principals/%u";
};

environment.etc."ssh/auth_principals/jmo".text = "jmo\n";
```

Important: `AuthorizedPrincipalsFile` must resolve outside `/nix/store`. OpenSSH
refuses principals files that resolve into `/nix/store` and logs
`bad ownership or modes for directory /nix/store`, which breaks CA auth even
when the CA/principal are correct. Keep `/etc/ssh/auth_principals/<user>` as a
real file (not a symlink into the store).

### KRL revoke (optional)

Sign with a serial for revoke support:

```bash
ssh-keygen -s "$HOME/.ssh/ca/ssh_user_ca" \
  -I "<host>-$(date +%Y%m%d)" \
  -n "jmo" \
  -V +30d \
  -z <serial> \
  "$HOME/.ssh/host_<hostname>.pub"
```

Revoke by serial (generate/update KRL):

```bash
ssh-keygen -k -f "$HOME/.ssh/ca/revoked.krl" -s "$HOME/.ssh/ca/ssh_user_ca" -z <serial>
```

On servers, set:

```
services.openssh.settings.RevokedKeys = "/etc/ssh/revoked.krl";
```

### Renewal script (example)

```bash
#!/usr/bin/env bash
set -euo pipefail

CA_KEY="$HOME/.ssh/ca/ssh_user_ca"
PRINCIPALS="jmo"
DAYS=30

sign_key() {
  local pubkey="$1"
  local name="$2"
  local serial="$3"

  ssh-keygen -s "$CA_KEY" \
    -I "${name}-$(date +%Y%m%d)" \
    -n "$PRINCIPALS" \
    -V "+${DAYS}d" \
    -z "$serial" \
    "$pubkey"
}

sign_key "$HOME/.ssh/host_overton.pub" "overton" 1
```

## Battery Management

### Status and Diagnostics

```bash
# Comprehensive battery information
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Show all power devices
upower -d

# Quick status checks
cat /sys/class/power_supply/BAT0/status      # "Charging" or "Discharging"
cat /sys/class/power_supply/BAT0/capacity    # Battery percentage
```

### TLP Battery Management

```bash
# Check TLP battery settings and thresholds
sudo tlp-stat -b

# Force update battery charge thresholds
sudo tlp setcharge 0 80 BAT0  # START=0%, STOP=80%

# Restart TLP service to apply new settings
sudo systemctl restart tlp.service

# Full TLP status report
sudo tlp-stat
```

### Temporarily Disable Battery Protection

```bash
# Stop UPower service (disables auto-suspend at 35% until restart)
sudo systemctl stop upower

# Re-enable UPower
sudo systemctl start upower
```

## Hyprland

### Window Management

```bash
# List all windows
hyprctl clients

# Get active window info
hyprctl activewindow

# List workspaces
hyprctl workspaces

# Get current monitor info
hyprctl monitors

# Reload Hyprland config
hyprctl reload
```

### Debugging

```bash
# Check Hyprland version
hyprland -v

# Validate config without applying
hyprland --config ~/.config/hypr/hyprland.conf --verify-config

# View Hyprland logs
journalctl --user -b 0 | grep -i hyprland
```

## Kanata Keyboard Remapping

```bash
# Check service status
systemctl status kanata-laptop.service

# View live logs
sudo journalctl -u kanata-laptop.service -f

# Restart service
sudo systemctl restart kanata-laptop.service

# View recent logs
sudo journalctl -u kanata-laptop.service -n 50
```

## Podman / Containers

```bash
# List running containers
podman ps

# List all containers (including stopped)
podman ps -a

# View container logs
podman logs <container_name>

# Start/stop containers
podman start <container_name>
podman stop <container_name>

# Remove stopped containers
podman container prune

# List images
podman images

# Remove unused images
podman image prune
```

## Audio (Pipewire)

```bash
# List audio devices
pactl list sinks
pactl list sources

# Set default sink
pactl set-default-sink <sink_name>

# Restart pipewire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check pipewire status
systemctl --user status pipewire
```

## Bluetooth

```bash
# Open bluetoothctl interactive shell
bluetoothctl

# Quick commands
bluetoothctl power on
bluetoothctl scan on
bluetoothctl devices
bluetoothctl connect <MAC_ADDRESS>
bluetoothctl disconnect <MAC_ADDRESS>

# Check bluetooth service
systemctl status bluetooth
```

## Network

```bash
# List WiFi networks
nmcli device wifi list

# Connect to WiFi
nmcli device wifi connect <SSID> password <PASSWORD>

# Show connection status
nmcli connection show

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check if online
ping 1.1.1.1
```

## Syncthing

```bash
# Check service status
systemctl --user status syncthing.service

# View logs
journalctl --user -u syncthing.service -f

# Restart service
systemctl --user restart syncthing.service

# Web interface usually at: http://localhost:8384
```

## Terminal Tools

### Zellij

```bash
# List sessions
zellij list-sessions

# Attach to session
zellij attach <session_name>

# Kill session
zellij kill-session <session_name>

# Delete all sessions
zellij delete-all-sessions
```

### Atuin (Shell History)

```bash
# Sync history
atuin sync

# Search history (or Ctrl+R)
atuin search <query>

# Show stats
atuin stats

# Check sync status
atuin status
```

### Jujutsu (Version Control)

```bash
# Status
jj status

# Log
jj log

# Add/commit changes
jj commit -m "message"

# Rebase
jj rebase -d <destination>

# Undo last operation
jj undo

# Show help
jj help
```

## Services Status

```bash
# List failed services
systemctl --failed
systemctl --user --failed

# View service logs
journalctl -u <service_name> -f

# Restart a service
sudo systemctl restart <service_name>
systemctl --user restart <service_name>
```

## Display/Graphics

```bash
# List displays (Wayland)
wlr-randr

# Check graphics info
lspci | grep -i vga

# Check if running Wayland
echo $XDG_SESSION_TYPE
```

### Niri Per-Display Layout Profiles (Overton)

This setup keeps the current ultrawide behavior as the global default, and only
overrides layout width presets on the laptop panel.

```nix
# defs/home-manager/niri.nix
programs.niri.settings = {
  outputs = {
    # Ultrawide keeps global layout defaults
    "DVI-I-1" = {
      mode = {
        width = 5120;
        height = 1440;
        refresh = 59.977;
      };
      scale = 1.25;
    };

    # Laptop uses wider default + wider preset cycle
    "eDP-1" = {
      mode = {
        width = 1920;
        height = 1080;
        refresh = 60.0;
      };
      scale = 1.25;
      layout = {
        default-column-width = { proportion = 2.0 / 3.0; };
        preset-column-widths = [
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
          { proportion = 3.0 / 4.0; }
          { proportion = 5.0 / 6.0; }
        ];
      };
    };
  };

  # Global defaults (used by ultrawide and as fallback)
  layout = {
    preset-column-widths = [
      { proportion = 1.0 / 3.0; }
      { proportion = 1.0 / 2.0; }
      { proportion = 2.0 / 3.0; }
    ];
    default-column-width = { proportion = 1.0 / 2.0; };
  };
};
```

This depends on the `niri-flake` branch with per-output `layout` support:

```nix
# flake.nix
inputs.niri.url = "github:ohare93/niri-flake/layout-per-display";
```

Useful runtime check:

```bash
niri msg outputs
```

## Disk Usage

```bash
# Check disk space
df -h

# Check directory sizes
du -sh *

# Find large files
du -ah ~ | sort -rh | head -20

# Clean nix store
nix-store --gc
sudo nix-collect-garbage -d
```

## SSH / GPG

```bash
# Check SSH agent
ssh-add -l

# Add SSH key
ssh-add ~/.ssh/id_ed25519

# GPG list keys
gpg --list-keys

# Check gpg-agent
gpg-connect-agent /bye
```

## Quick Diagnostics

```bash
# System info
neofetch
# or
fastfetch

# Resource usage
htop

# Process tree
pstree

# Check boot time
systemd-analyze blame

# Journal since last boot
journalctl -b
```
