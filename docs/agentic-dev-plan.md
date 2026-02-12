# Agentic Dev Environment Plan

## Goals
- Keep the base system fully reproducible via nixfiles/Home Manager.
- Enable autonomous, background agent loops with minimal friction.
- Allow flexible per-repo environments without touching third-party repos.
- Avoid global tool/caches conflicts in sandboxed environments.
- Keep caches fast but bounded via time-based cleanup.

## Directory Layout
Lifecycle-first structure:

~/Development/
  active/
    personal/
    work/
    oss/
    tools/
  shaping/
  archive/
  external/
  scratch/
  worktrees/
  _ops/
    envs/
    caches/
    runs/
  _meta/

Notes:
- Keep ~/Development/.claude and ~/Development/worktrees at root.
- Move existing repos into ~/Development/archive/inbox, then manually promote.

## Repo Key Strategy (Stable Across Moves)
- Primary: `jj git remote list`
- Fallback: `git remote -v`
- Remote selection priority: origin -> gitea -> github -> first listed
- Canonicalize to `host/owner/repo` (strip scheme/user/port and `.git`)
- Fallback if no remotes:
  - Use repo-local `.repo-id` (untracked, in global gitignore)
  - Optional manual overrides in `~/Development/_meta/registry.json`

## Environment Resolution (Automatic, Per-Repo)
Mechanism: direnv with per-repo `.envrc` calling `use_dev_env`.

Resolution order:
1) `devbox.json` in repo -> devbox
2) `flake.nix` in repo -> `use flake`
3) Overlay `~/Development/_ops/envs/<repo_key>/devbox.json` -> devbox
4) Else fallback to global tools

Per-repo `.envrc` content:
```
use_dev_env
```

## Cache Strategy (Per-Repo)
All caches live under:
`~/Development/_ops/caches/<repo_key>`

Environment variables on activation:
- Node/TS: `NPM_CONFIG_CACHE`, `YARN_CACHE_FOLDER`, `PNPM_STORE_DIR`
- Rust: `CARGO_HOME`, `RUSTUP_HOME`, `SCCACHE_DIR`
- Go: `GOMODCACHE`, `GOCACHE`
- Elm: `ELM_HOME`
- XDG: `XDG_CACHE_HOME`

## Cache Cleanup
- Track last use via `<cache_root>/.last_used`
- Policy: delete caches unused for 30 days
- Schedule: weekly on Saturday (systemd user timer)

## Overlay Environments (Third-Party Repos)
- Store overlays at `~/Development/_ops/envs/<repo_key>/devbox.json`
- Keeps third-party repos clean while still reproducible locally

## Nix-Managed Sources of Truth
Managed in `~/nixfiles` (Home Manager):
- `~/.config/direnv/direnvrc` (resolver logic)
- `~/.config/systemd/user/dev-cache-prune.{service,timer}`
- `~/.config/git/ignore`
- `~/Development/_ops/bin/dev-cache-prune` (script)

Global gitignore entries:
- `.envrc`
- `.direnv/`
- `.repo-id`

## JJ Workspace Helper
`jjw` creates quick jj workspaces and enters them:
- `jjw <name>` -> `~/Development/worktrees/<name>` with `jj init`
- `jjw <url> [area]` -> clone into `~/Development/<area>/<repo>` (default area: worktrees)
- Writes `.envrc` with `use_dev_env` and runs `direnv allow`

## Build Command
Use `nh os build --no-nom` (preferred) for evaluation/builds.

## Implementation Files Added
- `defs/home-manager/agentic-dev.nix`
- `defs/home-manager/scripts/dev-cache-prune`
- `modules/aspects/hm-agentic-dev.nix`
- Updates to:
  - `defs/home-manager/default.nix`
  - `defs/home-manager/devbox.nix`
  - `defs/home-manager/git.nix`
  - `defs/home-manager/scripts/zsh_extras`
  - `modules/aspects/hm-desktop-dev.nix`
  - `AGENTS.md`

## Activation
Apply via:
```
nh os switch --no-nom
```

## Validation Checklist
- `direnv` activates per repo using `use_dev_env`
- Repo key remains stable across repo moves
- Per-repo caches are used for npm/cargo/go/elm
- Weekly cache cleanup runs on Saturday
- `jjw` creates workspaces under `~/Development/worktrees`
