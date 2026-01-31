{
  lib,
  config,
  pkgs,
  inputs,
  hostname,
  ...
}: let
  cfg = config.mynix.terminal-misc;
  fzfCommand = "rg --files --hidden --glob '!.git' --glob '!.jj'";
in
  with lib; {
    options.mynix = {
      terminal-misc = {
        zoxide.enable = mkEnableOption "zoxide";
        zellij.enable = mkEnableOption "zellij";
        atuin.enable = mkEnableOption "atuin";
        fzf.enable = mkEnableOption "fzf";
        carapace.enable = mkEnableOption "carapace";
        claude.enable = mkEnableOption "claude";
        codex.enable = mkEnableOption "codex";
        gemini.enable = mkEnableOption "gemini";
        devbox.enable = mkEnableOption "devbox";
        poetry.enable = mkEnableOption "poetry";
        comma.enable = mkEnableOption "comma";
        gren.enable = mkEnableOption "gren";
        nvd.enable = mkEnableOption "nvd";
        opencode.enable = mkEnableOption "opencode";
      };
    };

    config = {
      home.file.".local/bin/nrb" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          nix build ~/nixfiles#nixosConfigurations.${hostname}.config.system.build.toplevel -o /tmp/result-new
          if command -v nvd >/dev/null 2>&1; then
            nvd diff /run/current-system /tmp/result-new
          else
            echo "nvd not found; build complete at /tmp/result-new" >&2
          fi
        '';
      };

      home.packages =
        lib.optional cfg.claude.enable pkgs.llm-agents.claude-code
        ++ lib.optional cfg.codex.enable pkgs.llm-agents.codex
        ++ lib.optional cfg.gemini.enable pkgs.llm-agents.gemini-cli
        ++ lib.optional cfg.devbox.enable pkgs.devbox
        ++ lib.optional cfg.comma.enable pkgs.comma
        ++ lib.optional cfg.gren.enable pkgs.gren
        ++ lib.optional cfg.nvd.enable pkgs.nvd
        ++ lib.optional cfg.opencode.enable pkgs.llm-agents.opencode;

      xdg.configFile = mkMerge [
        (mkIf cfg.zellij.enable {
          "zellij/config.kdl".source = ./config/zellij.kdl;
          # TEMPORARILY DISABLED to test if zjstatus causes flickering/glitching
          # "zellij/zjstatus.kdl".source = ./config/zjstatus.kdl;
          # "zellij/check-alerts.sh" = {
          #   source = ./config/zellij-check-alerts.sh;
          #   executable = true;
          # };
          # "zellij/plugins/zjstatus.wasm".source = "${pkgs.zjstatus}/bin/zjstatus.wasm";
        })
      ];

      programs = {
        zoxide = mkIf cfg.zoxide.enable {
          enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
        };

        zellij = mkIf cfg.zellij.enable {
          enable = true;
          enableZshIntegration = true;
          attachExistingSession =
            config.programs.zellij.enableZshIntegration
            || config.programs.zellij.enableBashIntegration
            || config.programs.zellij.enableFishIntegration;
        };

        atuin = mkIf cfg.atuin.enable {
          enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = false; # Disabled due to deprecation warning, using custom integration
          daemon.enable = true;
          settings = {
            auto_sync = true;
            sync_frequency = "5m";
            sync_address = inputs.private.services.atuin;
            search_mode = "fuzzy";
            filter_mode = "host";
            show_preview = true;
            enter_accept = true;
          };
        };

        fzf = mkIf cfg.fzf.enable {
          enable = true;
          enableZshIntegration = true;
          defaultCommand = fzfCommand;
          changeDirWidgetCommand = fzfCommand;
          fileWidgetOptions = ["--glob '!.git'" "--glob '!.jj'"];
        };

        poetry = mkIf cfg.poetry.enable {
          enable = true;
          settings = {
            virtualenvs.create = true;
            virtualenvs.in-project = true;
          };
        };

        carapace = mkIf cfg.carapace.enable {
          enable = true;
          enableNushellIntegration = config.mynix.nushell.enable or false;
          enableZshIntegration = config.mynix.zsh.enable or false;
        };
      };
    };
  }
