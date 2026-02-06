{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.mynix.ssh;
in
  with lib; {
    options.mynix = {
      ssh = {
        enable = mkEnableOption "ssh agent";
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
            };

            "gitea" = {
              hostname = inputs.private.services.gitea.domain;
              user = "git";
              inherit (inputs.private.services.gitea) port;
              identityFile = [inputs.private.ssh.identityFiles.gitea];
              identitiesOnly = true;
            };
            "private-git" = {
              hostname = inputs.private.services.gitea.domain;
              user = "git";
              inherit (inputs.private.services.gitea) port;
              identityFile = [inputs.private.ssh.identityFiles.gitea];
              identitiesOnly = true;
            };
            "unraid" = {
              hostname = inputs.private.services.thebox;
              proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
              identityFile = inputs.private.ssh.identityFiles.unraid;
              identitiesOnly = true;
            };
            "github-ohare" = {
              hostname = "github.com";
              identityFile = inputs.private.ssh.identityFiles.github;
              identitiesOnly = true;
            };
            "github-dc" = {
              hostname = "github.com";
              identityFile = inputs.private.ssh.identityFiles.githubDc;
              identitiesOnly = true;
            };
            "cloud" = {
              hostname = inputs.private.services.cloud.domain;
              inherit (inputs.private.services.cloud) port;
              inherit (inputs.private.services.cloud) user;
              identityFile = [inputs.private.ssh.identityFiles.cloud];
              identitiesOnly = true;
            };
          }
          // (inputs.private.ssh.matchBlocks or {});
      };

      home.activation.addAllSSHKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [[ -n "$XDG_RUNTIME_DIR" ]]; then
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
        fi
        for key in $HOME/.ssh/id_*; do
          if [[ -f "$key" && "$key" != *.pub ]]; then
            ssh-add "$key" 2>/dev/null || true
          fi
        done
      '';
    };
  }
