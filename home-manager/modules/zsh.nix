{
  lib,
  config,
  pkgs,
  hostname,
  ...
}: let
  cfg = config.mynix.zsh;
  sharedAliases = import ./shared-aliases.nix {inherit lib hostname;};
  customPackages = import ../packages {inherit pkgs lib;};
in
  with lib; {
    options.mynix = {
      zsh.enable = mkEnableOption "zsh";
      zsh.showAliasExpansion = mkOption {
        type = types.bool;
        default = true;
        description = "Show alias expansion before command execution for learning";
      };
    };

    config = {
      home.file.".zshrc_functions".source = ../scripts/zsh_extras;

      programs = {
        zsh = mkIf cfg.enable {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;

          plugins = [
            {
              name = "zsh-vi-mode";
              src = pkgs.zsh-vi-mode;
              file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
            }
            {
              name = "zsh-ai-cmd";
              src = customPackages.zsh-ai-cmd;
              file = "share/zsh-ai-cmd/zsh-ai-cmd.plugin.zsh";
            }
          ];

          initContent = lib.mkOrder 550 (''
              source_if_exists() {
                if [[ -f "$1" ]]; then
                  source "$1"
                fi
              }

              source_if_exists ~/.zshrc_private_keys
              source_if_exists ~/.zshrc_functions

              # Initialize carapace if available
              if command -v carapace &> /dev/null; then
                export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
                source <(carapace _carapace)
              fi
            ''
            + lib.optionalString cfg.showAliasExpansion ''

              # Show alias expansion before execution (for learning)
              preexec() {
                local cmd="$1"
                local first_word="''${cmd%% *}"

                # Check if first word is an alias
                local alias_def="$(alias "$first_word" 2>/dev/null)"

                if [[ -n "$alias_def" ]]; then
                  # Extract just the command part (after the =)
                  local expansion="''${alias_def#*=}"
                  expansion="''${expansion#\'}"  # Remove leading quote
                  expansion="''${expansion%\'}"  # Remove trailing quote
                  echo "\033[2m→ $expansion\033[0m" >&2
                fi
              }
            '');

          shellAliases =
            sharedAliases.commonAliases
            // (sharedAliases.shellSpecificAliases "zsh")
            // sharedAliases.zshComplexAliases;

          history.size = 10000;
          history.ignoreAllDups = true;
          history.path = "$HOME/.zsh_history";
        };
      };
    };
  }
