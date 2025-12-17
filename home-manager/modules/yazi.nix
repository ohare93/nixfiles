{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.yazi;
in
  with lib; {
    options.mynix = {
      yazi = {
        enable = mkEnableOption "Yazi terminal file manager with customizations";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.yazi
        pkgs.ripdrag
        pkgs.xdg-desktop-portal-termfilechooser
      ];

      # Yazi keymap configuration
      xdg.configFile."yazi/keymap.toml".text = ''
        # Drop to shell - press ! to open $SHELL in current directory
        [[mgr.prepend_keymap]]
        on   = "!"
        run  = 'shell "''$SHELL" --block'
        desc = "Open shell here"

        # ripdrag - press D (Shift+D) for drag-and-drop
        [[mgr.prepend_keymap]]
        on   = "D"
        run  = "shell 'ripdrag \"''$@\" -x 2>/dev/null &' --confirm"
        desc = "Drag and drop with ripdrag"

        # Yank and copy to clipboard (Wayland)
        [[mgr.prepend_keymap]]
        on  = "y"
        run = [ "shell -- for path in \"''$@\"; do echo \"file://''$path\"; done | wl-copy -t text/uri-list", "yank" ]
        desc = "Yank and copy to clipboard"
      '';

      # Yazi init.lua - status bar customization and plugin loading
      xdg.configFile."yazi/init.lua".text = ''
        -- Show user/group in status bar
        Status:children_add(function()
          local h = cx.active.current.hovered
          if not h or ya.target_family() ~= "unix" then
            return ""
          end
          return ui.Line {
            ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
            ":",
            ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
            " ",
          }
        end, 500, Status.RIGHT)

        -- Load folder-rules plugin for Downloads sorting
        require("folder-rules"):setup()
      '';

      # Folder rules plugin - sorts Downloads by modification time
      xdg.configFile."yazi/plugins/folder-rules.yazi/main.lua".text = ''
        local function setup()
          ps.sub("cd", function()
            local cwd = cx.active.current.cwd
            if cwd:ends_with("Downloads") then
              ya.emit("sort", { "mtime", reverse = true, dir_first = false })
            else
              ya.emit("sort", { "alphabetical", reverse = false, dir_first = true })
            end
          end)
        end

        return { setup = setup }
      '';

      # xdg-desktop-portal-termfilechooser configuration
      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=yazi-wrapper.sh
        default_dir=''$HOME
        env=TERMCMD=kitty
      '';

      # XDG portal preference - use termfilechooser for file dialogs
      xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
        [preferred]
        org.freedesktop.impl.portal.FileChooser=termfilechooser
      '';

      # Yazi wrapper script for xdg-desktop-portal-termfilechooser
      home.file.".local/bin/yazi-wrapper.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # Wrapper script for xdg-desktop-portal-termfilechooser
          # Arguments: $1 = action (open/save), $2 = output file, $3+ = starting path

          action="''$1"
          output_file="''$2"
          shift 2

          if [[ "''$action" == "save" ]]; then
            # For save dialogs, yazi needs --chooser-file
            ''$TERMCMD -e yazi --chooser-file="''$output_file" "''$@"
          else
            # For open dialogs
            ''$TERMCMD -e yazi --chooser-file="''$output_file" "''$@"
          fi
        '';
      };
    };
  }
