# NixOS Configuration Project Instructions

## Build Workflow

**IMPORTANT: Use `nh os build .` for testing, NOT `nh os switch`**

- All builds use `nixos-rebuild` or `nh` commands
- Home-manager is integrated into nixos-rebuild - do NOT use `home-manager switch` or similar standalone commands
- For testing: `nh os build .` or `nh os build . --no-nom`
- The `.` is required — there is no default flake path configured, so `nh os build` without a path will fail. This is intentional to prevent accidentally building the wrong worktree.
- NEVER run `nh os switch` or `nixos-rebuild switch` unless explicitly instructed by the user
- The user will decide when to actually switch to a new configuration

## Package Management

- Custom packages are defined in `defs/home-manager/packages/`
- Packages are integrated through the NixOS configuration, not standalone home-manager
