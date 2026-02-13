{
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.mynix.agentic-dev;
in
  with lib; {
    options.mynix.agentic-dev = {
      enable = mkEnableOption "agentic development environment";

      devRoot = mkOption {
        type = types.str;
        default = inputs.private.paths.development;
        description = "Root directory for Development layout";
      };

      cacheRetentionDays = mkOption {
        type = types.int;
        default = 30;
        description = "Days to keep unused per-repo caches";
      };

      cacheCleanupOnCalendar = mkOption {
        type = types.str;
        default = "Sat";
        description = "systemd OnCalendar value for cache cleanup";
      };
    };

    config = mkIf cfg.enable {
      home.sessionVariables = {
        DEV_ROOT = cfg.devRoot;
      };

      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
        config = {
          global = {
            strict_env = true;
            hide_env_diff = true;
          };
          direnvrc = mkAfter ''
            export DEV_ROOT="${cfg.devRoot}"

            __repo_root() {
              local root
              if command -v jj >/dev/null 2>&1; then
                root="$(jj root 2>/dev/null)" && [ -n "$root" ] && { echo "$root"; return; }
              fi
              if command -v git >/dev/null 2>&1; then
                root="$(git rev-parse --show-toplevel 2>/dev/null)" && [ -n "$root" ] && { echo "$root"; return; }
              fi
              pwd
            }

            __jj_remote_url() {
              command -v jj >/dev/null 2>&1 || return 0
              jj git remote list 2>/dev/null | awk '
                $1=="origin" {origin=$2}
                $1=="gitea" {gitea=$2}
                $1=="github" {github=$2}
                $2!="" && first=="" {first=$2}
                END {
                  if (origin!="") print origin;
                  else if (gitea!="") print gitea;
                  else if (github!="") print github;
                  else if (first!="") print first;
                }'
            }

            __git_remote_url() {
              command -v git >/dev/null 2>&1 || return 0
              git remote -v 2>/dev/null | awk '
                $1=="origin" && $3=="(fetch)" {origin=$2}
                $1=="gitea" && $3=="(fetch)" {gitea=$2}
                $1=="github" && $3=="(fetch)" {github=$2}
                $3=="(fetch)" && first=="" {first=$2}
                END {
                  if (origin!="") print origin;
                  else if (gitea!="") print gitea;
                  else if (github!="") print github;
                  else if (first!="") print first;
                }'
            }

            __canonicalize_remote() {
              local url="$1"
              local u
              u="$(printf '%s' "$url" | sed -E 's#^[^/]+://##')"
              u="$(printf '%s' "$u" | sed -E 's#^[^@]+@##')"
              u="$(printf '%s' "$u" | sed -E 's#^([^/]+):[0-9]+/#\1/#')"
              u="$(printf '%s' "$u" | sed -E 's#^([^/]+):#\1/#')"
              u="$(printf '%s' "$u" | sed -E 's#\.git$##; s#/$##')"
              echo "$u"
            }

            __registry_key() {
              local root="$1"
              local registry="$DEV_ROOT/_meta/registry.json"
              if [ -f "$registry" ] && command -v jq >/dev/null 2>&1; then
                jq -r --arg path "$root" '.[$path] // empty' "$registry"
              fi
            }

            __repo_key() {
              local root="$1"
              local key
              key="$(__registry_key "$root")"
              if [ -n "$key" ]; then
                echo "$key"
                return
              fi

              local url
              url="$(__jj_remote_url)"
              if [ -z "$url" ]; then
                url="$(__git_remote_url)"
              fi
              if [ -n "$url" ]; then
                __canonicalize_remote "$url"
                return
              fi

              if [ -f "$root/.repo-id" ]; then
                cat "$root/.repo-id"
                return
              fi

              if command -v uuidgen >/dev/null 2>&1; then
                uuidgen > "$root/.repo-id"
              elif command -v python3 >/dev/null 2>&1; then
                python3 - <<'PY' > "$root/.repo-id"
import uuid
print(uuid.uuid4())
PY
              else
                date +%s%N > "$root/.repo-id"
              fi

              cat "$root/.repo-id"
            }

            __set_caches() {
              local cache_root="$1"
              export XDG_CACHE_HOME="$cache_root/xdg"
              export NPM_CONFIG_CACHE="$cache_root/npm"
              export YARN_CACHE_FOLDER="$cache_root/yarn"
              export PNPM_STORE_DIR="$cache_root/pnpm"
              export CARGO_HOME="$cache_root/cargo"
              export RUSTUP_HOME="$cache_root/rustup"
              export SCCACHE_DIR="$cache_root/sccache"
              export GOMODCACHE="$cache_root/go/mod"
              export GOCACHE="$cache_root/go/build"
              export ELM_HOME="$cache_root/elm"
            }

            __touch_last_used() {
              local cache_root="$1"
              mkdir -p "$cache_root"
              touch "$cache_root/.last_used"
            }

            __devbox_shellenv() {
              command -v devbox >/dev/null 2>&1 || return 0
              local config="$1"
              local out

              if [ -n "$config" ]; then
                if out="$(DEVBOX_CONFIG="$config" devbox shellenv --init-hook 2>/dev/null)"; then
                  eval "$out"
                  return
                fi
                if out="$(DEVBOX_CONFIG="$config" devbox shellenv 2>/dev/null)"; then
                  eval "$out"
                  return
                fi
                if out="$(DEVBOX_CONFIG="$config" devbox print-env 2>/dev/null)"; then
                  eval "$out"
                  return
                fi
                return
              fi

              if out="$(devbox shellenv --init-hook 2>/dev/null)"; then
                eval "$out"
                return
              fi
              if out="$(devbox shellenv 2>/dev/null)"; then
                eval "$out"
                return
              fi
              if out="$(devbox print-env 2>/dev/null)"; then
                eval "$out"
                return
              fi
            }

            use_dev_env() {
              local root key cache overlay

              root="$(__repo_root)"
              key="$(__repo_key "$root")"
              if [ -z "$key" ]; then
                return 0
              fi

              cache="$DEV_ROOT/_ops/caches/$key"
              overlay="$DEV_ROOT/_ops/envs/$key/devbox.json"

              __set_caches "$cache"
              __touch_last_used "$cache"

              if [ -f "$root/devbox.json" ]; then
                __devbox_shellenv
                return
              fi

              if [ -f "$root/flake.nix" ]; then
                if type use >/dev/null 2>&1; then
                  use flake "$root"
                fi
                return
              fi

              if [ -f "$overlay" ]; then
                __devbox_shellenv "$overlay"
              fi
            }
          '';
        };
      };

      home.file."${cfg.devRoot}/_ops/bin/dev-cache-prune" = {
        source = ./scripts/dev-cache-prune;
        executable = true;
      };

      home.activation.devOpsDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "${cfg.devRoot}/_ops/envs" \
          "${cfg.devRoot}/_ops/caches" \
          "${cfg.devRoot}/_ops/runs" \
          "${cfg.devRoot}/_meta"
      '';

      systemd.user.services.dev-cache-prune = {
        Unit = {
          Description = "Prune Development caches";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${cfg.devRoot}/_ops/bin/dev-cache-prune";
          Environment = [
            "DEV_ROOT=${cfg.devRoot}"
            "DAYS=${toString cfg.cacheRetentionDays}"
          ];
        };
      };

      systemd.user.timers.dev-cache-prune = {
        Unit = {
          Description = "Weekly prune Development caches";
        };
        Timer = {
          OnCalendar = cfg.cacheCleanupOnCalendar;
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };
    };
  }
