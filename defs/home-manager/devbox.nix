{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.devbox;
in
  with lib; {
    options.mynix.devbox = {
      enable = mkEnableOption "devbox development environment";

      enhancedShell = mkOption {
        type = types.bool;
        default = true;
        description = "Enable enhanced shell features for devbox";
      };

      direnv = mkOption {
        type = types.bool;
        default = true;
        description = "Enable direnv integration for automatic devbox activation";
      };
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        devbox
      ];

      # Enhanced shell configuration for devbox
      programs.zsh.initContent = mkIf cfg.enhancedShell (lib.mkOrder 1200 ''
        # Devbox shell helpers
        devbox_auto_shell() {
          if [[ -f devbox.json && -z "$DEVBOX_SHELL_ENABLED" && -z "$DEVBOX_PROJECT_ROOT" ]]; then
            echo "🚀 Devbox environment detected. Run 'devbox shell' to enter."
          fi
        }

        # Auto-check for devbox on cd
        autoload -U add-zsh-hook
        add-zsh-hook chpwd devbox_auto_shell
      '');

      # Global devbox configuration
      home.file.".devbox/global/devbox.json" = mkIf cfg.enhancedShell {
        text = builtins.toJSON {
          packages = [
            "git@latest"
            "curl@latest"
            "jq@latest"
            "ripgrep@latest"
            "fd@latest"
            "bat@latest"
            "eza@latest"
          ];
          shell = {
            init_hook = [
              "echo 'Global devbox environment loaded'"
              "export DEVBOX_GLOBAL=1"
            ];
            scripts = {
              update-global = "devbox update && echo 'Global devbox updated'";
              list-global = "devbox packages list";
            };
          };
        };
      };

      # Direnv integration for seamless devbox activation
      programs.direnv = mkIf cfg.direnv {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
        config = {
          global = {
            # Auto-allow devbox projects in trusted directories
            strict_env = true;
            hide_env_diff = true;
          };
          direnvrc = mkIf (!config.mynix.agentic-dev.enable) (mkAfter ''
            # Enhanced devbox integration
            use_devbox() {
              if [[ -f devbox.json ]]; then
                echo "Loading devbox environment..."
                eval "$(devbox print-env)"
                export DEVBOX_SHELL_ENABLED=1
              fi
            }

            # Auto-activate devbox for projects
            layout_devbox() {
              if [[ -f devbox.json ]]; then
                use_devbox
              fi
            }
          '');
        };
      };
    };
  }
