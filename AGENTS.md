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

## Agentic Dev Environment

The agentic dev environment (`mynix.agentic-dev`) provides direnv-based per-repo environment resolution with isolated caches and scheduled cleanup. Enabled via `mynix.agentic-dev.enable = true`.

### `use_dev_env` — direnv function

Add `use_dev_env` to a repo's `.envrc` to activate. It resolves the environment in this order:

1. **`devbox.json`** in repo root — runs `devbox shellenv`
2. **`flake.nix`** in repo root — runs `use flake` (nix-direnv)
3. **Overlay** at `$DEV_ROOT/_ops/envs/<key>/devbox.json` — runs `devbox shellenv` with that config
4. If none match, only per-repo caches are set (no extra packages)

### Repo key derivation

Each repo gets a unique key used for cache and overlay paths. Resolution order:

1. **Registry** — `$DEV_ROOT/_meta/registry.json` maps absolute paths to keys
2. **Remote URL** — jj remote (then git remote), canonicalized: strip protocol, userinfo, port, `.git` suffix. Priority: `origin` > `gitea` > `github` > first found
3. **`.repo-id`** file — fallback for repos with no remote. Auto-generated (UUID) if missing

### Per-repo caches

`use_dev_env` sets these environment variables, all under `$DEV_ROOT/_ops/caches/<key>/`:

| Variable | Subpath |
|---|---|
| `XDG_CACHE_HOME` | `xdg` |
| `NPM_CONFIG_CACHE` | `npm` |
| `YARN_CACHE_FOLDER` | `yarn` |
| `PNPM_STORE_DIR` | `pnpm` |
| `CARGO_HOME` | `cargo` |
| `RUSTUP_HOME` | `rustup` |
| `SCCACHE_DIR` | `sccache` |
| `GOMODCACHE` | `go/mod` |
| `GOCACHE` | `go/build` |
| `ELM_HOME` | `elm` |

A `.last_used` marker is touched on each activation for cache pruning.

### Overlay environments

To add packages for a third-party repo (where you can't commit a `devbox.json`), create an overlay:

```
$DEV_ROOT/_ops/envs/<key>/devbox.json
```

Where `<key>` is the repo's canonicalized remote URL (e.g. `github.com/owner/repo`). The overlay is only used when the repo has no `devbox.json` or `flake.nix` of its own.

### Cache cleanup

A systemd user timer (`dev-cache-prune.timer`) runs weekly (default: Saturday) and deletes cache directories whose `.last_used` marker is older than 30 days (configurable via `mynix.agentic-dev.cacheRetentionDays`).

### `jjw` — workspace helper

`jjw` is a wrapper for the jj-workspace-helper binary. Commands that produce a target directory (`create`, `select`, `cd`, `main`) automatically `cd` into it via a zsh function.

### Directory layout

```
$DEV_ROOT/
  _ops/
    bin/dev-cache-prune    # pruning script (managed by Home Manager)
    caches/<key>/          # per-repo isolated caches
    envs/<key>/            # overlay devbox.json files
    runs/                  # (reserved)
  _meta/
    registry.json          # optional path-to-key overrides
```

### Key implementation files

- `defs/home-manager/agentic-dev.nix` — module: options, direnv config, systemd units, activation
- `defs/home-manager/scripts/dev-cache-prune` — cache pruning script
- `defs/home-manager/packages/jj-workspace-helper.nix` — `jjw` package wrapper
- `defs/home-manager/scripts/zsh_extras` — `jjw` shell function (cd integration)
- `defs/home-manager/git.nix` — global gitignore for `.envrc`, `.direnv/`, `.repo-id`, `.jjw/`

### Testing / validation

After `nh os switch .`, verify the setup:

```bash
# Confirm DEV_ROOT is set
echo $DEV_ROOT

# Verify directory structure exists
ls $DEV_ROOT/_ops/{caches,envs,runs} $DEV_ROOT/_meta

# Check systemd timer is active
systemctl --user status dev-cache-prune.timer

# Test in a repo: create .envrc, allow it, confirm cache vars
cd ~/some-repo
echo 'use_dev_env' > .envrc
direnv allow
echo $XDG_CACHE_HOME   # should be under $DEV_ROOT/_ops/caches/<key>/xdg

# Test overlay: create devbox.json for a third-party repo
# (only applies if repo has no devbox.json or flake.nix)
mkdir -p $DEV_ROOT/_ops/envs/github.com/owner/repo
echo '{ "packages": ["python@3.12"] }' > $DEV_ROOT/_ops/envs/github.com/owner/repo/devbox.json
```
