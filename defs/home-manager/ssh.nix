{
  lib,
  config,
  pkgs,
  inputs,
  hostname,
  ...
}: let
  cfg = config.mynix.ssh;
  serviceKeyNames = ["gitea" "unraid" "github" "githubDc" "cloud"];
  defaultServiceKeyPaths = {
    gitea = "~/.ssh/svc_gitea";
    unraid = "~/.ssh/svc_unraid";
    github = "~/.ssh/svc_github";
    githubDc = "~/.ssh/svc_github_dc";
    cloud = "~/.ssh/svc_cloud";
  };
  serviceKeyPaths = cfg.keyPaths.services;
  expandHome = path: lib.replaceStrings ["~/"] ["${config.home.homeDirectory}/"] path;
  keysToAdd =
    [cfg.keyPaths.host]
    ++ map (name: serviceKeyPaths.${name}) serviceKeyNames
    ++ cfg.extraAgentKeys;
  addKeyLines = lib.concatMapStringsSep "\n" (key: ''add_key ${lib.escapeShellArg (expandHome key)}'') keysToAdd;
in
  with lib; {
    options.mynix = {
      ssh = {
        enable = mkEnableOption "ssh agent";
        keyPaths = {
          host = mkOption {
            type = types.str;
            default = "~/.ssh/host_${hostname}";
            description = "Preferred host key name for this machine.";
          };
          services = mkOption {
            type = types.attrsOf types.str;
            default = defaultServiceKeyPaths;
            description = "Preferred service key names.";
          };
          age = mkOption {
            type = types.str;
            default = "~/.ssh/age_${hostname}";
            description = "Preferred agenix key name for this machine.";
          };
        };
        extraAgentKeys = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Additional keys to add to the SSH agent.";
        };
      };
    };

    config = mkIf cfg.enable {
      services.ssh-agent.enable = true;

      home.sessionVariables = {
        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
      };

      home.packages = with pkgs; [
        cloudflared
      ];

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks =
          {
            "*" = {
              addKeysToAgent = "yes";
              identitiesOnly = true;
              identityFile = cfg.keyPaths.host;
            };

            "gitea private-git ${inputs.private.services.gitea.domain} ${inputs.private.selfhost.sites.personalMain}" = {
              hostname = inputs.private.services.gitea.domain;
              user = "git";
              inherit (inputs.private.services.gitea) port;
              identityFile = [serviceKeyPaths.gitea];
              identitiesOnly = true;
            };
            "unraid" = {
              hostname = inputs.private.services.thebox;
              proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
              identityFile = [serviceKeyPaths.unraid];
              identitiesOnly = true;
            };
            "github.com github-ohare" = {
              hostname = "github.com";
              identityFile = [serviceKeyPaths.github];
              identitiesOnly = true;
            };
            "github-dc" = {
              hostname = "github.com";
              identityFile = [serviceKeyPaths.githubDc];
              identitiesOnly = true;
            };
            "cloud" = {
              hostname = inputs.private.services.cloud.domain;
              inherit (inputs.private.services.cloud) port;
              inherit (inputs.private.services.cloud) user;
              identityFile = [serviceKeyPaths.cloud];
              identitiesOnly = true;
            };
          }
          // (inputs.private.ssh.matchBlocks or {});
      };

      home.activation.addAllSSHKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [[ -n "$XDG_RUNTIME_DIR" ]]; then
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
        fi

        add_key() {
          local key="$1"
          if [[ -f "$key" ]]; then
            ssh-add "$key" 2>/dev/null || true
          fi
        }

        ${addKeyLines}
      '';
    };
  }
