# Private Configuration Setup

This repository uses a separate private flake (`nixfiles.private`) hosted on Gitea to store personal information that you may not want public. This approach enables:

- ✅ Pure Nix evaluation (no `--impure` flag needed)
- ✅ Version control for private configuration
- ✅ Public nixfiles repo on GitHub without exposing private data
- ✅ Clean separation of public and private config

> **⚠️ Important**: This is **NOT** for secrets like API keys, passwords, or tokens. Use agenix for actual secrets that require encryption. This private flake is only for minimizing exposure of personal information (domains, device IDs, email addresses, etc.) that doesn't need cryptographic protection but you'd prefer not to make public.

## Repository Structure

The `nixfiles.private` repository is a separate Nix flake with the following structure:

```
nixfiles.private/
├── flake.nix          # Main flake that exports all config
├── user.nix           # Identity and filesystem paths
├── services.nix       # Service URLs and SSH keys
├── syncthing.nix      # Syncthing devices and folders
└── .gitignore         # Protect sensitive files
```

## Example Templates

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

## Setup Instructions

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

## Bootstrap Configuration (Required)

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

## Usage in Configuration

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

## Updating Private Configuration

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
