{
  lib,
  config,
  hostname,
  ...
}: let
  cfg = config.mynix.starship;

  # Generate a deterministic color from a hostname
  # Takes a string and returns a hex color
  hostnameToColor = hostname: let
    # Hash the hostname to get a number
    hash = builtins.hashString "sha256" hostname;

    # Convert first 6 characters of hash to a color
    # This gives us a hex color from the hash
    color = builtins.substring 0 6 hash;
  in "#${color}";

  # Get the hostname color
  hostnameColor = hostnameToColor hostname;
in
  with lib; {
    options.mynix = {
      starship = {
        enable = mkEnableOption "starship prompt";
      };
    };

    config = mkIf cfg.enable {
      programs.starship = {
        enable = true;
        enableZshIntegration = config.mynix.zsh.enable;
        enableNushellIntegration = config.mynix.nushell.enable;

        settings = {
          format = lib.concatStrings [
            "[░▒▓](#a3aed2)"
            "[  ](bg:#a3aed2 fg:#090c0c)"
            "[](bg:${hostnameColor} fg:#a3aed2)"
            "$hostname"
            "[](bg:#769ff0 fg:${hostnameColor})"
            "$directory"
            "[](fg:#769ff0 bg:#394260)"
            "$git_branch"
            "$git_status"
            "[](fg:#769ff0 bg:#394220)"
            "\${custom.jj}"
            "[](fg:#394260 bg:#212736)"
            "$nodejs"
            "$rust"
            "$golang"
            "$php"
            "[](fg:#212736 bg:#1d2230)"
            "$time"
            "[](fg:#1d2230 bg:#33658a)"
            "$shell"
            "[ ](fg:#33658a)"
            "\n$character"
          ];

          hostname = {
            ssh_only = false;
            style = "fg:#090c0c bg:${hostnameColor}";
            format = "[ $hostname ]($style)";
            disabled = false;
          };

          directory = {
            style = "fg:#e3e5e5 bg:#769ff0";
            format = "[ $path ]($style)";
            truncation_length = 3;
            truncation_symbol = "…/";
            substitutions = {
              "Documents" = "󰈙 ";
              "Downloads" = " ";
              "Music" = " ";
              "Pictures" = " ";
            };
          };

          git_branch = {
            symbol = "";
            style = "bg:#394260";
            format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
          };

          git_status = {
            style = "bg:#394260";
            format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
          };

          custom.jj = {
            style = "bg:#394220";
            command = "prompt";
            format = "$output";
            ignore_timeout = true;
            shell = ["starship-jj" "--ignore-working-copy" "starship" "--config-file" "$HOME/.config/starship/starship-jj.toml"];
            use_stdin = false;
            when = true;
          };

          nodejs = {
            symbol = "";
            style = "bg:#212736";
            format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
          };

          rust = {
            symbol = "";
            style = "bg:#212736";
            format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
          };

          golang = {
            symbol = "";
            style = "bg:#212736";
            format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
          };

          php = {
            symbol = "";
            style = "bg:#212736";
            format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
          };

          time = {
            disabled = false;
            time_format = "%R"; # Hour:Minute Format
            style = "bg:#1d2230";
            format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
          };

          shell = {
            disabled = false;
            style = "bg:#33658a";
            format = "[[ $indicator ](fg:#e3e5e5 bg:#33658a)]($style)";
            zsh_indicator = "zsh";
            bash_indicator = "bash";
            fish_indicator = "fish";
            nu_indicator = "nu";
          };

          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
            vimcmd_symbol = "[❮](bold green)";
          };
        };
      };

      # Create the jj-specific config file
      xdg.configFile."starship/starship-jj.toml".text = ''
        module_separator = " "

        [bookmarks]
        search_depth = 100
        exclude = []

        [[module]]
        type = "Symbol"
        symbol = "󱗆 "
        color = "Blue"

        [[module]]
        type = "Bookmarks"
        separator = " "
        color = "Magenta"
        behind_symbol = "⇡"

        [[module]]
        type = "Commit"
        max_length = 24

        [[module]]
        type = "State"
        separator = " "

        [module.conflict]
        disabled = false
        text = "(CONFLICT)"
        color = "Red"

        [module.divergent]
        disabled = false
        text = "(DIVERGENT)"
        color = "Cyan"

        [module.empty]
        disabled = false
        text = "(EMPTY)"
        color = "Yellow"

        [module.immutable]
        disabled = false
        text = "(IMMUTABLE)"
        color = "Yellow"

        [module.hidden]
        disabled = false
        text = "(HIDDEN)"
        color = "Yellow"

        [[module]]
        type = "Metrics"
        template = "[{changed} {added}{removed}]"
        color = "Magenta"

        [module.changed_files]
        prefix = ""
        suffix = ""
        color = "Cyan"

        [module.added_lines]
        prefix = "+"
        suffix = ""
        color = "Green"

        [module.removed_lines]
        prefix = "-"
        suffix = ""
        color = "Red"
      '';
    };
  }
