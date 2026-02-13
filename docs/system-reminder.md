# Agentic Development Environment Plan (System Reminder)

## Context
Goal is to run long, autonomous agentic loops on NixOS with minimal friction, while keeping the base system fully reproducible. Per-repo environments can be flexible and are allowed to be more imperative. Major pain points are sandboxed cache access, global tools, and network or sandbox limits.

## Goals
- Keep NixOS base reproducible (Home Manager plus nixfiles are the source of truth).
- Provide automatic per-repo environments with minimal manual setup.
- Route tool caches per-repo to avoid global cache conflicts in sandboxed agents.
- Allow overlay environments for third-party repos without modifying upstream.
- Maintain env and cache continuity after moving repos.
- Clean up caches on a schedule (time-based).

## Non-Goals
- Enforce full reproducibility for every third-party repo.
- Require changes to third-party repos (no committed devbox or flake files).
- Replace the existing agent tooling.

## Directory Layout
Target lifecycle structure:

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
- Move everything else into ~/Development/archive/inbox and manually promote later.

## Repo Key Strategy (Stable Across Moves)
- Primary: `jj git remote list`
- Fallback: `git remote -v`
- Remote selection priority:
  1) origin
  2) gitea
  3) github
  4) first listed remote
- Canonicalize to `host/owner/repo`:
  - Strip scheme, user, port
  - Convert `git@host:owner/repo` to `host/owner/repo`
  - Strip `.git`
- Fallback if no remote:
  - Use repo-local `.repo-id` (untracked, in global gitignore)
  - Optional registry in `~/Development/_meta/registry.json` for manual overrides

## Env Resolution (Automatic, Per-Repo)
Mechanism: direnv with per-repo `.envrc`, calling shared logic in `~/.config/direnv/direnvrc`.

Resolution order:
1) If repo has `devbox.json` -> use devbox
2) Else if repo has `flake.nix` -> use nix-direnv `use flake`
3) Else if overlay exists in `_ops/envs/<repo_key>/devbox.json` -> use devbox overlay
4) Else fallback to base tools (global runtimes ok)

Per-repo `.envrc` content:
- `use_dev_env`

## Cache Strategy (Per-Repo, Sandbox-Friendly)
Cache root:
- `~/Development/_ops/caches/<repo_key>`

Environment variables set on activation:
- Node/TS: `NPM_CONFIG_CACHE`, `YARN_CACHE_FOLDER`, `PNPM_STORE_DIR`
- Rust: `CARGO_HOME`, `RUSTUP_HOME`, `SCCACHE_DIR` (optional)
- Go: `GOMODCACHE`, `GOCACHE`
- Elm: `ELM_HOME`
- XDG: `XDG_CACHE_HOME`

## Cache Cleanup (Time-Based)
Policy: delete caches unused for 30 days.
Tracking:
- Touch `<cache_root>/.last_used` on env activation.

Schedule:
- Weekly on Saturday via systemd user timer.

## Overlay Environments for Third-Party Repos
- Stored at `~/Development/_ops/envs/<repo_key>/devbox.json`
- Enables clean, reproducible shells without modifying third-party repos.

## Source of Truth
- Declarative config in `~/nixfiles` (Home Manager):
  - `~/.config/direnv/direnvrc`
  - `~/.config/systemd/user/dev-cache-prune.{service,timer}`
  - `~/.config/git/ignore`
- Operational outputs:
  - `~/Development/_ops/*` for caches, overlays, logs, helper scripts

## Global Gitignore Entries
- `.envrc`
- `.direnv/`
- `.repo-id`
- `.jjw/` (optional, user choice)

## JJ Workspace Helper
- Use a dedicated Go tool `jjw` (`jj-workspace-helper`) instead of ad-hoc shell scripts.
- Default behavior is repo-scoped workspace management under `~/Development/worktrees/<app>/<workspace>`.
- Current-repo commands: `create`, `list`, `select`, `tidy`, `cd`.
- Name assignment can be explicit or auto-picked from configured lists.
- Global config: `~/.config/jjw/config.yaml`.
- Local per-repo override: `<repo-root>/.jjw/config.yaml`.
- Stateful naming cursor: `<repo-root>/.jjw/state.json`.

## Implementation Steps (High Level)
1) Create lifecycle directory structure.
2) Move all repos into `~/Development/archive/inbox` (manual promote later).
3) Add direnv shared logic and per-repo `.envrc` files.
4) Add cache routing and XDG cache isolation.
5) Add cache cleanup script and weekly systemd timer.
6) Seed overlay devbox configs for third-party repos as needed.

## Validation Checklist
- Direnv activates automatically per repo.
- Repo key resolves via jj or git and is stable after moves.
- npm, cargo, go, and elm caches are per-repo.
- Cache cleanup runs weekly and respects 30-day policy.
- Overlays work for third-party repos with no repo modifications.
