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
