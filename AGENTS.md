# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Overview

This is a NixOS configuration repository with Home Manager integration. It manages system configurations for multiple hosts using Nix flakes and provides declarative dotfile management through Home Manager.

## Architecture

The repository is structured around three main components:

1. **Dendritic Modules** (`modules/`): Flake-parts modules, aspects, and flake outputs
2. **Module Definitions** (`defs/`): `mynix` option definitions for NixOS/Home Manager plus host asset files
3. **Host Aspects** (`modules/hosts/`, `modules/hardware/`): Per-host system/service and hardware compositions

Key architectural patterns:

- Custom module system with `mynix` namespace for reusable configurations
- Hostname-based conditional configuration (GUI software only enabled for "overton")
- Unfree package allowlist managed centrally in `flake.nix`
- NVF integration for comprehensive Neovim configuration split across multiple files

## Links / References

The links to the necessary tools used in this repository. These should be referenced frequently, especially when making a change in an area of the code featuring these tools. Example uses:

- Installing a package one should reference the Home Manager options, then the NixOS options / packages. GUI apps should generally live in `defs/home-manager/gui-software.nix` and be enabled via host aspects, as I don't need GUI apps in WSL.
- When adding a new option or package into neovim, the NVF options should be referenced to figure out what are the correct / possible values, and one should always favour nvf implementations over home-manager or nix specific implementations.

### NixOS

- Git repo (nixpkgs): https://github.com/NixOS/nixpkgs
- Manual: https://nixos.org/manual/nixos/stable/
- Packages: https://search.nixos.org/packages?channel=unstable

### Home Manager

- Git repo: https://github.com/nix-community/home-manager/
- Manual: https://nix-community.github.io/home-manager/
- Options: https://nix-community.github.io/home-manager/options.xhtml
- Options (user friendly query): https://home-manager-options.extranix.com/?query=zsh&release=release-25.05

### NVF

- Git repo: https://github.com/NotAShelf/nvf
- Manual: https://notashelf.github.io/nvf/index.xhtml
- Options: https://notashelf.github.io/nvf/options.html

### Misc

https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration

## Development Commands

### Building and Testing

```bash
# Build NixOS system configuration (includes Home Manager)
nh os build --no-nom

# Update flake inputs
nix flake update

```

**Important**: This configuration uses Home Manager as a NixOS module. Use `nh os build --no-nom` for builds and avoid `nixos-rebuild` commands. There is no separate `home-manager switch` command.
