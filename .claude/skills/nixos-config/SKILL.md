---
name: nixos-config
description: Use when working with NixOS configurations, Home Manager setups, Nix flakes, services, or troubleshooting Nix builds. Covers creating new configurations, modifying existing ones, adding packages, setting up services, writing modules, and debugging build failures.
---

# NixOS Configuration Skill

**Announce at start**: "I'm using the nixos-config skill to work with your Nix configuration."

## Critical Reminders

- **Flakes only** — never use channels or `nix-env`
- **Declarative always** — never use imperative approaches when declarative solutions exist
- **jj new before building** — new files must be tracked; run `jj new` so they appear in git HEAD
- **Always build-test** — never consider the task complete without a successful build
- **Clean up result symlinks** — remove any `result` symlinks created during builds

## Quick Reference

| Task | Command |
|---|---|
| Rebuild NixOS (test) | `sudo nixos-rebuild test --flake .#<hostname>` |
| Rebuild NixOS (switch) | `sudo nixos-rebuild switch --flake .#<hostname>` |
| Home Manager build | `home-manager build --flake .#user@hostname --no-out-link` |
| Home Manager switch | `home-manager switch --flake .#user@hostname` |
| Check flake | `nix flake check` |
| Evaluate expression | `nix-instantiate --eval -E '<expr>'` |
| Interactive REPL | `nix repl` |
| Show derivation | `nix show-derivation` |
| Update single input | `nix flake update <input>` |
| Update all inputs | `nix flake update` |

## Workflow

### Phase 1: Analyze Existing Configuration

Before making changes, understand the current setup:

1. Read `flake.nix` to understand inputs, outputs, and structure
2. Identify the module organization pattern (flat vs nested, custom namespaces like `mynix`)
3. Check for existing conventions:
   - Option naming patterns
   - Module enable/disable patterns
   - Import structure
   - Custom library functions
4. Note the hostname(s) and user(s) configured

### Phase 2: Plan Changes

Determine scope and approach:

1. **NixOS vs Home Manager** — system-level services and kernel config go in NixOS modules; user programs, dotfiles, and user services go in Home Manager
2. **New module vs existing** — prefer extending existing modules unless the feature is clearly separate
3. **Option design** — plan option names, types, and defaults that match existing conventions
4. Explain the planned changes to the user before implementing

### Phase 3: Implement

Write the configuration following Nix best practices:

- Use `lib.mkEnableOption` for boolean toggles
- Use `lib.mkOption` with proper types (`types.str`, `types.listOf`, `types.attrsOf`, etc.)
- Use `lib.mkIf` for conditional configuration
- Use `lib.mkDefault` for defaults that users can override
- Use `lib.mkForce` sparingly and only when necessary
- Use `lib.mkMerge` to combine multiple config blocks
- Use `lib.assertMsg` for meaningful error messages on invalid config
- Respect the project's existing conventions and namespaces
- Add description strings to custom options

### Phase 4: Validate and Build

1. If new files were created, run `jj new` so they are tracked
2. Build and test:
   - **NixOS**: `sudo nixos-rebuild test --flake .#<hostname>`
   - **Home Manager**: `home-manager build --flake .#user@hostname --no-out-link`
3. Run `nix flake check` if structural changes were made to the flake
4. Clean up any `result` symlinks: `rm -f result`
5. Squash related changes if needed: `jj squash`

### Phase 5: Troubleshoot If Build Fails

If the build fails, follow this process:

1. **Parse the error message** — identify the failing module, option, or derivation
2. **Use debugging tools**:
   - `nix-instantiate --eval` to test expressions in isolation
   - `nix repl` to interactively explore values
   - `nix show-derivation` to inspect build dependencies
3. **Fix the issue** and rebuild
4. **Repeat** until the build succeeds

## Error Handling

### Common Failure Patterns

| Error | Cause | Fix |
|---|---|---|
| `error: getting status of '/nix/store/.../<file>'` | New file not tracked by git | Run `jj new` to snapshot, then rebuild |
| `error: attribute 'X' missing` | Typo in option name or missing import | Check spelling, verify module is imported in `flake.nix` |
| `error: infinite recursion encountered` | Circular dependency between options | Break the cycle with `lib.mkMerge` or restructure |
| `error: value is a X while a Y was expected` | Wrong option type | Check `mkOption` type declaration matches usage |
| `error: option 'X' does not exist` | Module not imported or option path wrong | Verify import chain and option path |
| `collision between '/nix/store/...'` | Two packages provide same file | Use `lib.mkForce` or `packageOverrides` to resolve |
| `error: flake 'X' does not provide attribute` | Wrong output path in flake | Check `nixosConfigurations` / `homeConfigurations` names |

### Build Fails After Adding New Files

This is the most common issue. New files are not visible to the Nix evaluator until they are tracked:

```bash
jj new          # snapshot new files into git HEAD
# then rebuild
```

Remember to squash related changes afterward if needed.

## Key Principles

1. **Declarative** — every configuration choice should be expressed declaratively in Nix
2. **Minimal changes** — make targeted changes that integrate with existing patterns
3. **Validate before done** — never claim completion without a passing build
4. **Respect conventions** — follow the project's established module structure, naming, and namespaces
5. **Explain changes** — describe what was changed and why, highlight breaking changes or migration needs

## Resources

Reference materials are available in the `references/` directory:

- `nix-language.md` — Nix language syntax and builtins
- `flake-patterns.md` — Flake structure, inputs, and overlays
- `nixos-modules.md` — Module structure, option declarations, and config patterns
- `home-manager.md` — Home Manager modules, programs, and services
- `troubleshooting.md` — Error catalog, debugging workflow, and migration patterns
