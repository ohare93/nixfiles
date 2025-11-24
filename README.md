# NixOS Configuration Quick Reference

Personal quick reference for common commands and debugging.

## Private Configuration Setup

This repository uses a separate private flake (`nixfiles.private`) hosted on Gitea to store personal information that you may not want public. This approach enables:

- ✅ Pure Nix evaluation (no `--impure` flag needed)
- ✅ Version control for private configuration
- ✅ Public nixfiles repo on GitHub without exposing private data
- ✅ Clean separation of public and private config

> **⚠️ Important**: This is **NOT** for secrets like API keys, passwords, or tokens. Use [agenix](https://github.com/ryantm/agenix) for actual secrets that require encryption. This private flake is only for minimizing exposure of personal information (domains, device IDs, email addresses, etc.) that doesn't need cryptographic protection but you'd prefer not to make public.

### Repository Structure

The `nixfiles.private` repository is a separate Nix flake with the following structure:

```
nixfiles.private/
├── flake.nix          # Main flake that exports all config
├── user.nix           # Identity and filesystem paths
├── services.nix       # Service URLs and SSH keys
├── syncthing.nix      # Syncthing devices and folders
└── .gitignore         # Protect sensitive files
```

### Example Templates

<details>
<summary><b>flake.nix</b> - Main entry point</summary>

```nix
{
  description = "Private configuration for NixOS systems";

  outputs = {self, ...}: let
    user = import ./user.nix;
    services = import ./services.nix;
  in {
    # Export individual components for clean access
    identity = user.identity;
    paths = user.paths;
    services = services.services;
    ssh = services.ssh;
    syncthing = import ./syncthing.nix;
  };
}
```

</details>

<details>
<summary><b>user.nix</b> - Identity and paths</summary>

```nix
{
  identity = {
    username = "your-username";
    fullName = "Your Full Name";
    email = "your-email@example.com";
  };

  paths = {
    home = "/home/your-username";
    nixfiles = "/home/your-username/nixfiles";
    sync = "/home/your-username/sync";
    development = "/home/your-username/Development";
  };
}
```

</details>

<details>
<summary><b>services.nix</b> - Service URLs and SSH keys</summary>

```nix
{
  services = {
    gitea = {
      domain = "git.yourdomain.com";
      port = 22;  # Your Gitea SSH port
    };
    immich = "https://immich.yourdomain.com";
    ntfy = "https://ntfy.yourdomain.com";
    atuin = "https://atuin.yourdomain.com";
    unraid = "https://unraid.yourdomain.com";
  };

  ssh = {
    identityFiles = {
      gitea = "~/.ssh/id_gitea";
      unraid = "~/.ssh/id_unraid";
      github = "~/.ssh/id_github";
      githubDc = "~/.ssh/id_dc";
    };
  };
}
```

</details>

<details>
<summary><b>syncthing.nix</b> - Syncthing configuration</summary>

```nix
{
  devices = {
    device1 = { id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX"; };
    device2 = { id = "YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY"; };
    device3 = { id = "ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ"; };
  };

  folders = {
    fileShare = {
      id = "xxxxx-xxxxx";
      label = "FileShare";
    };
    documents = {
      id = "yyyyy-yyyyy";
      label = "Documents";
    };
    photos = {
      id = "zzzzz-zzzzz";
      label = "Photos";
    };
  };
}
```

</details>

<details>
<summary><b>.gitignore</b> - Protect sensitive files</summary>

```gitignore
# Keep the repo clean
result
result-*

# Nix build outputs
.direnv/

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db
```

</details>

### Setup Instructions

1. **Create the private repository** on your Gitea instance (e.g., `nixfiles.private`)

2. **Initialize the repository locally**:

   ```bash
   mkdir ~/nixfiles-private
   cd ~/nixfiles-private
   jj git init  # Or: git init

   # Create the files from templates above
   nvim flake.nix user.nix services.nix syncthing.nix .gitignore

   # Commit
   jj commit -m "Initial commit: Add private configuration"
   ```

3. **Push to Gitea**:

   ```bash
   git remote add origin git@your-gitea.com:port/username/nixfiles.private.git
   git push -u origin main
   ```

4. **Configure main nixfiles flake** to use the private input:

   ```nix
   # In flake.nix inputs:
   inputs = {
     # ... other inputs
     private = {
       url = "git+ssh://git@your-gitea.com:port/username/nixfiles.private";
     };
   };
   ```

5. **Update flake.lock**:
   ```bash
   cd ~/nixfiles
   nix flake lock --update-input private
   ```

### Bootstrap Configuration (Required)

The main `flake.nix` uses an abstract URL (`git+ssh://private-config`) to hide server details. You must configure SSH and Git **before** building the configuration:

**Add to `~/.ssh/config`**:
```ssh
Host private-git
    HostName your-gitea-domain.com
    Port YOUR_SSH_PORT
    User git
    IdentityFile ~/.ssh/your_gitea_key
```

**Add to `~/.gitconfig`**:
```gitconfig
[url "ssh://private-git/your-username/"]
    insteadOf = git+ssh://private-config
```

Replace the placeholders with your actual Gitea configuration details.

**Why this is needed**: The flake input URL is abstracted to avoid exposing server details in the public repository. These configurations map the abstract URL to your actual Gitea instance.

### Usage in Configuration

Access private values using `inputs.private.*`:

```nix
# In modules/configuration files:
{config, inputs, ...}: {
  # Identity
  home.username = inputs.private.identity.username;
  programs.git.userEmail = inputs.private.identity.email;

  # Paths
  home.homeDirectory = inputs.private.paths.home;

  # Services
  programs.atuin.settings.sync_address = inputs.private.services.atuin;

  # SSH
  programs.ssh.matchBlocks."gitea".identityFile = inputs.private.ssh.identityFiles.gitea;

  # Syncthing
  services.syncthing.settings.devices = inputs.private.syncthing.devices;
}
```

### Updating Private Configuration

```bash
# 1. Make changes in nixfiles-private
cd ~/nixfiles-private
nvim services.nix  # or any other file

# 2. Commit and push
jj commit -m "Update service URLs"
git push

# 3. Update main nixfiles
cd ~/nixfiles
nix flake lock --update-input private

# 4. Build/test
nh os build --no-nom
```

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
