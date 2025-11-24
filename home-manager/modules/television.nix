{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.television;
in
  with lib; {
    options.mynix = {
      television = {
        enable = mkEnableOption "television fuzzy finder";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.television];

      xdg.configFile."television/config.toml".text = ''
        # General settings
        tick_rate = 50

        [ui]
        use_nerd_font_icons = false
        ui_scale = 100
        show_help_bar = false
        show_preview_panel = true
        input_bar_position = "top"
        theme = "default"

        [previewers.file]
        theme = "TwoDark"

        [keybindings]
        # Application control
        esc = "quit"
        ctrl-c = "quit"

        # Selection and navigation
        enter = "confirm_selection"
        down = "select_next_entry"
        ctrl-n = "select_next_entry"
        ctrl-j = "select_next_entry"
        up = "select_prev_entry"
        ctrl-p = "select_prev_entry"
        ctrl-k = "select_prev_entry"
        pagedown = "select_next_page"
        pageup = "select_prev_page"

        # Multi-selection
        tab = "toggle_selection_down"
        backtab = "toggle_selection_up"

        # Preview panel control
        ctrl-d = "scroll_preview_half_page_down"
        ctrl-u = "scroll_preview_half_page_up"

        # Data operations
        ctrl-y = "copy_entry_to_clipboard"
        ctrl-s = "toggle_send_to_channel"

        # UI features
        ctrl-o = "toggle_preview"
        ctrl-g = "toggle_help"
        ctrl-r = "toggle_remote_control"

        [shell_integration]
        fallback_channel = "files"

        [shell_integration.channel_triggers]
        alias = ["alias", "unalias"]
        env = ["export", "unset"]
        dirs = ["cd", "ls", "rmdir"]
        files = [
          "cat", "less", "head", "tail", "vim", "nano", "bat",
          "cp", "mv", "rm", "touch", "chmod", "chown", "ln",
          "tar", "zip", "unzip", "gzip", "gunzip", "xz"
        ]
        git-diff = ["git add", "git restore"]
        git-branch = [
          "git checkout", "git branch", "git merge",
          "git rebase", "git pull", "git push"
        ]
        docker-images = ["docker run"]
        git-repos = ["nvim", "code", "hx", "git clone"]

        [shell_integration.keybindings]
        smart_autocomplete = "ctrl-t"
        command_history = "ctrl-r"
      '';

      # Channel configurations moved to separate files
      xdg.configFile."television/cable/alias.toml".text = ''
        [metadata]
        name = "alias"
        requirements = []
        description = "Select from shell aliases"

        [source]
        command = "alias"

        [preview]
        command = "echo {}"
      '';

      xdg.configFile."television/cable/dirs.toml".text = ''
        [metadata]
        name = "dirs"
        description = "A channel to select from directories"
        requirements = ["fd"]

        [source]
        command = "fd -t d -H --exclude .git --exclude .jj"

        [preview]
        command = "ls -la {}"
      '';

      xdg.configFile."television/cable/docker-images.toml".text = ''
        [metadata]
        name = "docker-images"
        description = "A channel to select from docker images"
        requirements = ["docker"]

        [source]
        command = "docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}'"

        [preview]
        command = "docker inspect {split:\t:0} | head -50"
      '';

      xdg.configFile."television/cable/dotfiles.toml".text = ''
        [metadata]
        name = "dotfiles"
        description = "A channel to select from your user's dotfiles"
        requirements = ["fd", "bat"]

        [source]
        command = "fd -t f . \"$HOME/.config/\""

        [preview]
        command = "bat -n --color=always {}"
      '';

      xdg.configFile."television/cable/env.toml".text = ''
        [metadata]
        name = "env"
        description = "A channel to select from environment variables"
        requirements = []

        [source]
        command = "env"
        columns = ["variable", "value"]
        column_separator = "="

        [preview]
        command = "echo 'Variable: {column:variable}\n\nValue:\n{column:value}'"
      '';

      xdg.configFile."television/cable/files.toml".text = ''
        [metadata]
        name = "files"
        requirements = ["fd", "bat"]
        description = "A channel to select from files in your current directory"

        [source]
        command = "fd -t f -H --exclude .git --exclude .jj"

        [preview]
        command = "bat -n --color=always {}"
      '';

      xdg.configFile."television/cable/git-branch.toml".text = ''
        [metadata]
        name = "git-branch"
        requirements = ["git"]
        description = "A channel to select from git branches"

        [source]
        command = "git branch -a --format='%(refname:short)'"

        [preview]
        command = "git log {} --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h %d %s' -n 50"
      '';

      xdg.configFile."television/cable/git-diff.toml".text = ''
        [metadata]
        name = "git-diff"
        requirements = ["git", "bat"]
        description = "A channel to select from git diff files"

        [source]
        command = "git diff --name-only --diff-filter=ACMRT"

        [preview]
        command = "git diff --color=always {}"
      '';

      xdg.configFile."television/cable/git-log.toml".text = ''
        [metadata]
        name = "git-log"
        requirements = ["git"]
        description = "A channel to select from git log entries"

        [source]
        command = "git log --oneline -n 100"

        [preview]
        command = "git show --color=always {split: :0}"
      '';

      xdg.configFile."television/cable/git-reflog.toml".text = ''
        [metadata]
        name = "git-reflog"
        requirements = ["git"]
        description = "A channel to select from git reflog entries"

        [source]
        command = "git reflog -n 50"

        [preview]
        command = "git show --color=always {split: :0}"
      '';

      xdg.configFile."television/cable/git-repos.toml".text = ''
        [metadata]
        name = "git-repos"
        requirements = ["fd", "git"]
        description = "A channel to select from git repositories on your local machine."

        [source]
        command = "fd -g .git -HL -t d -d 10 --prune '$HOME' --exec dirname '{}'"
        display = "{split:/:-1}"

        [preview]
        command = "cd '{}'; git log -n 200 --pretty=medium --all --graph --color"
      '';

      xdg.configFile."television/cable/text.toml".text = ''
        [metadata]
        name = "text"
        requirements = ["rg"]
        description = "A channel to search for text in files using ripgrep."

        [source]
        command = "echo 'Enter search pattern in TV interface'"

        [source.interactive]
        command = "rg --color=always --line-number --no-heading --smart-case '{{input}}'"

        [preview]
        command = "bat -n --color=always --highlight-line {split::2} {split::1}"
      '';
    };
  }
