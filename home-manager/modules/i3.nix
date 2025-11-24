{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.i3;
in
  with lib; {
    options.mynix = {
      i3 = {
        enable = mkEnableOption "i3 Window Manager with Rofi and Polybar";
      };
    };

    config = mkIf cfg.enable {
      # Write i3 config directly
      home.file.".config/i3/config" = {
        force = true; # Overwrite existing regular file
        text = ''
          # i3 config file (v4)
          # Please see https://i3wm.org/docs/userguide.html for a complete reference!

          set $mod Mod4

          # Font for window titles
          font pango:Noto Sans 10

          # Start Polybar on startup
          exec_always --no-startup-id ~/.config/polybar/launch.sh

          # Start notification daemon
          exec --no-startup-id ${pkgs.dunst}/bin/dunst

          # Use Mouse+$mod to drag floating windows
          floating_modifier $mod

          # Terminal
          bindsym $mod+Return exec ${pkgs.alacritty}/bin/alacritty

          # Kill focused window
          bindsym $mod+Shift+q kill

          # App launcher (Rofi with icons)
          bindsym $mod+d exec ${pkgs.rofi}/bin/rofi -show drun -show-icons

          # Change focus (vim keys)
          bindsym $mod+h focus left
          bindsym $mod+j focus down
          bindsym $mod+k focus up
          bindsym $mod+l focus right

          # Arrow keys also work
          bindsym $mod+Left focus left
          bindsym $mod+Down focus down
          bindsym $mod+Up focus up
          bindsym $mod+Right focus right

          # Move focused window (vim keys)
          bindsym $mod+Shift+h move left
          bindsym $mod+Shift+j move down
          bindsym $mod+Shift+k move up
          bindsym $mod+Shift+l move right

          # Arrow keys also work
          bindsym $mod+Shift+Left move left
          bindsym $mod+Shift+Down move down
          bindsym $mod+Shift+Up move up
          bindsym $mod+Shift+Right move right

          # Split in horizontal orientation
          bindsym $mod+b split h

          # Split in vertical orientation
          bindsym $mod+v split v

          # Enter fullscreen mode for the focused container
          bindsym $mod+f fullscreen toggle

          # Change container layout (stacked, tabbed, toggle split)
          bindsym $mod+s layout stacking
          bindsym $mod+w layout tabbed
          bindsym $mod+e layout toggle split

          # Toggle tiling / floating
          bindsym $mod+Shift+space floating toggle

          # Change focus between tiling / floating windows
          bindsym $mod+space focus mode_toggle

          # Focus the parent container
          bindsym $mod+a focus parent

          # Define names for workspaces
          set $ws1 "1"
          set $ws2 "2"
          set $ws3 "3"
          set $ws4 "4"
          set $ws5 "5"
          set $ws6 "6"
          set $ws7 "7"
          set $ws8 "8"
          set $ws9 "9"
          set $ws10 "10"

          # Switch to workspace
          bindsym $mod+1 workspace number $ws1
          bindsym $mod+2 workspace number $ws2
          bindsym $mod+3 workspace number $ws3
          bindsym $mod+4 workspace number $ws4
          bindsym $mod+5 workspace number $ws5
          bindsym $mod+6 workspace number $ws6
          bindsym $mod+7 workspace number $ws7
          bindsym $mod+8 workspace number $ws8
          bindsym $mod+9 workspace number $ws9
          bindsym $mod+0 workspace number $ws10

          # Move focused container to workspace
          bindsym $mod+Shift+1 move container to workspace number $ws1
          bindsym $mod+Shift+2 move container to workspace number $ws2
          bindsym $mod+Shift+3 move container to workspace number $ws3
          bindsym $mod+Shift+4 move container to workspace number $ws4
          bindsym $mod+Shift+5 move container to workspace number $ws5
          bindsym $mod+Shift+6 move container to workspace number $ws6
          bindsym $mod+Shift+7 move container to workspace number $ws7
          bindsym $mod+Shift+8 move container to workspace number $ws8
          bindsym $mod+Shift+9 move container to workspace number $ws9
          bindsym $mod+Shift+0 move container to workspace number $ws10

          # Reload the configuration file
          bindsym $mod+Shift+c reload

          # Restart i3 inplace (preserves your layout/session)
          bindsym $mod+Shift+r restart

          # Exit i3
          bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes, exit i3' 'i3-msg exit'"

          # Resize window mode
          mode "resize" {
                  bindsym h resize shrink width 10 px or 10 ppt
                  bindsym j resize grow height 10 px or 10 ppt
                  bindsym k resize shrink height 10 px or 10 ppt
                  bindsym l resize grow width 10 px or 10 ppt

                  bindsym Left resize shrink width 10 px or 10 ppt
                  bindsym Down resize grow height 10 px or 10 ppt
                  bindsym Up resize shrink height 10 px or 10 ppt
                  bindsym Right resize grow width 10 px or 10 ppt

                  bindsym Return mode "default"
                  bindsym Escape mode "default"
                  bindsym $mod+r mode "default"
          }

          bindsym $mod+r mode "resize"

          # Window colors
          # class                 border  backgr. text    indicator child_border
          client.focused          #4c7899 #285577 #ffffff #2e9ef4   #285577
          client.focused_inactive #333333 #5f676a #ffffff #484e50   #5f676a
          client.unfocused        #333333 #222222 #888888 #292d2e   #222222
          client.urgent           #2f343a #900000 #ffffff #900000   #900000
          client.placeholder      #000000 #0c0c0c #ffffff #000000   #0c0c0c

          client.background       #ffffff

          # Window settings
          default_border pixel 2
          default_floating_border pixel 2
          hide_edge_borders none

          # Gaps
          gaps inner 10
          gaps outer 5

          # i3bar at the bottom
          bar {
                  position bottom
                  status_command i3status

                  colors {
                          background #222222
                          statusline #ffffff
                          separator #666666

                          focused_workspace  #4c7899 #285577 #ffffff
                          active_workspace   #333333 #5f676a #ffffff
                          inactive_workspace #333333 #222222 #888888
                          urgent_workspace   #2f343a #900000 #ffffff
                          binding_mode       #2f343a #900000 #ffffff
                  }
          }
        '';
      };

      # Write Polybar config
      home.file.".config/polybar/config.ini" = {
        force = true;
        text = ''
          [colors]
          background = #222222
          foreground = #ffffff
          primary = #4a90d9
          secondary = #76b900
          tertiary = #aa5cc3
          alert = #ba2922

          [bar/main]
          width = 100%
          height = 40
          radius = 0
          fixed-center = true

          background = ''${colors.background}
          foreground = ''${colors.foreground}

          line-size = 3
          line-color = #f00

          border-size = 0
          border-color = #00000000

          padding-left = 2
          padding-right = 2

          module-margin-left = 1
          module-margin-right = 1

          font-0 = Noto Sans:size=12;2
          font-1 = Noto Sans:size=12:weight=bold;2

          modules-left = i3
          modules-center = chromium moonlight jellyfin
          modules-right = date

          tray-position = right
          tray-padding = 2

          cursor-click = pointer
          cursor-scroll = ns-resize

          [module/i3]
          type = internal/i3
          format = <label-state> <label-mode>
          index-sort = true
          wrapping-scroll = false

          label-mode-padding = 2
          label-mode-foreground = #000
          label-mode-background = #ffb52a

          label-focused = %index%
          label-focused-background = #285577
          label-focused-underline = #4c7899
          label-focused-padding = 2

          label-unfocused = %index%
          label-unfocused-padding = 2

          label-visible = %index%
          label-visible-background = #333333
          label-visible-underline = #555555
          label-visible-padding = 2

          label-urgent = %index%
          label-urgent-background = ''${colors.alert}
          label-urgent-padding = 2

          [module/chromium]
          type = custom/text
          content = BROWSER
          content-foreground = ''${colors.primary}
          content-padding = 3
          content-font = 2
          click-left = ${pkgs.chromium}/bin/chromium &

          [module/moonlight]
          type = custom/text
          content = MOONLIGHT
          content-foreground = ''${colors.secondary}
          content-padding = 3
          content-font = 2
          click-left = ${pkgs.moonlight-qt}/bin/moonlight-qt &

          [module/jellyfin]
          type = custom/text
          content = JELLYFIN
          content-foreground = ''${colors.tertiary}
          content-padding = 3
          content-font = 2
          click-left = ${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer &

          [module/date]
          type = internal/date
          interval = 5

          date = %Y-%m-%d
          time = %H:%M

          label = %date% %time%
        '';
      };

      # Write Polybar launch script
      home.file.".config/polybar/launch.sh" = {
        text = ''
          #!/usr/bin/env bash

          # Terminate already running bar instances
          ${pkgs.killall}/bin/killall -q polybar

          # Wait until the processes have been shut down
          while ${pkgs.procps}/bin/pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

          # Launch polybar
          ${pkgs.polybar}/bin/polybar main 2>&1 | tee -a /tmp/polybar.log & disown

          echo "Polybar launched..."
        '';
        executable = true;
      };

      # Rofi configuration
      programs.rofi = {
        enable = true;
        theme = "Arc-Dark";
        terminal = "${pkgs.alacritty}/bin/alacritty";
        extraConfig = {
          modi = "drun,run,window";
          show-icons = true;
          icon-theme = "Papirus";
          display-drun = "Apps";
          display-run = "Run";
          display-window = "Windows";
          drun-display-format = "{name}";
          font = "Noto Sans 12";
        };
      };

      # Additional packages for visual appeal
      home.packages = with pkgs; [
        # Icon themes
        papirus-icon-theme

        # Fonts
        noto-fonts
        noto-fonts-emoji

        # Utilities
        xdotool
        xclip
        killall
        procps

        # Polybar
        polybar

        # i3 utilities
        i3lock
        i3status

        # For screenshots
        maim

        # Notification daemon
        dunst
      ];

      # GTK theme for better appearance
      gtk = {
        enable = true;
        theme = {
          name = "Arc-Dark";
          package = pkgs.arc-theme;
        };
        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
        };
      };

      # Disable dconf (not needed for i3, causes activation failures)
      dconf.enable = lib.mkForce false;

      # Enable notification daemon
      services.dunst = {
        enable = true;
        settings = {
          global = {
            font = "Noto Sans 11";
            geometry = "300x5-30+50";
            transparency = 10;
            frame_color = "#4c7899";
            timeout = 5;
          };
          urgency_low = {
            background = "#222222";
            foreground = "#888888";
          };
          urgency_normal = {
            background = "#285577";
            foreground = "#ffffff";
          };
          urgency_critical = {
            background = "#ba2922";
            foreground = "#ffffff";
            frame_color = "#ff0000";
          };
        };
      };
    };
  }
