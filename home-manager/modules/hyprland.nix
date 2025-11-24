{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.hyprland;
in
  with lib; {
    options.mynix = {
      hyprland = {
        enable = mkEnableOption "Hyprland Tiling Window Manager";
      };
    };

    config = mkIf cfg.enable {
      # Enable Hyprland
      wayland.windowManager.hyprland = {
        enable = true;

        # Enable systemd integration with all environment variables
        # This is required for hypridle service to access PATH
        systemd.variables = ["--all"];

        settings = {
          # Monitor configuration - explicit setup for DisplayLink ultrawide
          monitor = [
            # LG ULTRAGEAR+ curved ultrawide - native 5120x1440 resolution
            # Explicitly set to 5120x1440@59.98 (native ultrawide aspect ratio 32:9)
            # Use 'toggle-monitor' alias to switch to preferred mode when in PIP mode
            # Scale: 1.25x for comfortable text size
            "DVI-I-1,5120x1440@59.98,0x0,1.25"
            # Laptop screen - always enabled at startup with comfortable scaling
            # Will be disabled automatically via lid.sh when lid is closed with external monitor
            "eDP-1,1920x1080@60,auto,1.25"
            # Fallback for any other monitors
            ",preferred,auto,1"
          ];

          # Input configuration
          input = {
            kb_layout = "dk"; # Danish layout to match physical keyboard
            kb_variant = "";
            kb_model = "";
            kb_options = "";
            kb_rules = "";

            follow_mouse = 1;

            touchpad = {
              natural_scroll = true;
              disable_while_typing = true;
              tap-to-click = true;
            };

            sensitivity = 0; # -1.0 - 1.0, 0 means no modification
          };

          # General configuration
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";

            layout = "dwindle";
            allow_tearing = false;
          };

          # Decoration
          decoration = {
            rounding = 5;

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };
          };

          # Animations - smooth but not distracting
          animations = {
            enabled = true;

            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          # Layout configuration
          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          # Misc settings
          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            mouse_move_enables_dpms = true;
            key_press_enables_dpms = true;
          };

          # Environment variables for better Wayland support
          env = [
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
          ];

          # Window rules for better application handling
          windowrule = [
            "float, class:^pavucontrol$"
            "float, class:^blueman-manager$"
            "float, class:^nm-connection-editor$"
            "float, class:^file_progress$"
            "float, class:^confirm$"
            "float, class:^dialog$"
            "float, class:^download$"
            "float, class:^notification$"
            "float, class:^error$"
            "float, class:^splash$"
            "float, class:^confirmreset$"
            "float, title:^(Open File)(.*)$"
            "float, title:^(Select a File)(.*)$"
            "float, title:^(Choose wallpaper)(.*)$"
            "float, title:^(Open Folder)(.*)$"
            "float, title:^(Save As)(.*)$"
            "float, title:^(Library)(.*)$"
          ];

          # OMARCHY-INSPIRED KEYBOARD BINDINGS
          # Using SUPER as primary modifier following Omarchy principles
          "$mod" = "SUPER";

          # Application launchers - quick access to essential tools
          bind = [
            # Terminal - Super+Return (most important shortcut)
            "$mod, Return, exec, foot"

            # Browser - Super+B
            "$mod, B, exec, qutebrowser"

            # Application launcher - Super+D
            "$mod, D, exec, rofi -show drun"

            # Window management - core Omarchy-inspired bindings
            "$mod, W, killactive," # Close window
            "$mod, V, togglefloating," # Toggle floating
            "$mod, P, pseudo," # Pseudo tiling
            "$mod, J, togglesplit," # Toggle split
            "$mod, F, fullscreen," # Toggle fullscreen

            # Focus movement - Super + Arrow keys (with cursor auto-center)
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"

            # Focus movement - Vim-style (hjkl)
            "$mod, H, movefocus, l"
            "$mod, L, movefocus, r"
            "$mod, K, movefocus, u"
            "$mod, J, movefocus, d"

            # Workspace navigation - Super + numbers
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            "$mod, 6, workspace, 6"
            "$mod, 7, workspace, 7"
            "$mod, 8, workspace, 8"
            "$mod, 9, workspace, 9"
            "$mod, 0, workspace, 10"

            # Cycle through workspaces - Super + Tab/Shift+Tab
            "$mod, Tab, workspace, e+1"
            "$mod SHIFT, Tab, workspace, e-1"

            # Move windows to workspaces - Super + Shift + numbers
            "$mod SHIFT, 1, movetoworkspace, 1"
            "$mod SHIFT, 2, movetoworkspace, 2"
            "$mod SHIFT, 3, movetoworkspace, 3"
            "$mod SHIFT, 4, movetoworkspace, 4"
            "$mod SHIFT, 5, movetoworkspace, 5"
            "$mod SHIFT, 6, movetoworkspace, 6"
            "$mod SHIFT, 7, movetoworkspace, 7"
            "$mod SHIFT, 8, movetoworkspace, 8"
            "$mod SHIFT, 9, movetoworkspace, 9"
            "$mod SHIFT, 0, movetoworkspace, 10"

            # Window resizing
            "$mod CTRL, H, resizeactive, -20 0"
            "$mod CTRL, L, resizeactive, 20 0"
            "$mod CTRL, K, resizeactive, 0 -20"
            "$mod CTRL, J, resizeactive, 0 20"

            # Window moving
            "$mod SHIFT, H, movewindow, l"
            "$mod SHIFT, L, movewindow, r"
            "$mod SHIFT, K, movewindow, u"
            "$mod SHIFT, J, movewindow, d"

            # Special workspace (scratchpad)
            "$mod, S, togglespecialworkspace, magic"
            "$mod SHIFT, S, movetoworkspace, special:magic"

            # System controls
            "$mod SHIFT, Q, exit," # Exit Hyprland (with Shift for safety)
            "$mod SHIFT, R, exec, hyprctl reload" # Reload config
            "$mod, L, exec, hyprlock" # Lock screen

            # Help system - using the minus key (easily accessible)
            "$mod, minus, exec, ~/.config/hypr/keybinds-help.sh" # Show keybindings help (Super+-)
            "$mod SHIFT, slash, exec, foot -e hyprctl binds" # Show all binds in terminal

            # Screenshot with Hyprshot (Wayland-native)
            # All modes save to /tmp/screenshots and copy to clipboard for pasting
            ", Print, exec, hyprshot -m output -o /tmp/screenshots" # Full screen screenshot
            "$mod, Print, exec, hyprshot -m region -o /tmp/screenshots" # Select region screenshot
            "$mod SHIFT, Print, exec, hyprshot -m window -o /tmp/screenshots" # Active window screenshot
            "$mod ALT, Print, exec, sh -c 'FILE=/tmp/screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png && grim -g \"$(slurp)\" \"$FILE\" && echo -n \"$FILE\" | wl-copy && notify-send \"Screenshot\" \"Path copied: $FILE\"'" # Screenshot region, copy file path to clipboard

            # Speech-to-text - Super+R (R for Record/Recognize)
            "$mod, R, exec, ~/.local/bin/stt" # Start speech-to-text recording (10 seconds)
            "$mod SHIFT, R, exec, ~/.local/bin/stt 30" # Start speech-to-text recording (30 seconds)

            # Notification management with mako
            "$mod, N, exec, makoctl restore" # Restore last dismissed notification
            "$mod SHIFT, N, exec, makoctl dismiss --all" # Dismiss all notifications

            # Volume control (if not handled by Kanata)
            ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

            # Brightness control
            ", XF86MonBrightnessUp, exec, brightnessctl set 10%+"
            ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"

            # Display toggle - Super+Shift+Escape to switch between laptop/external monitor modes
            "$mod SHIFT, Escape, exec, ~/.config/hypr/toggle-display.sh"
          ];

          # Mouse bindings for window manipulation
          bindm = [
            "$mod, mouse:272, movewindow" # Super + left click to move
            "$mod, mouse:273, resizewindow" # Super + right click to resize
          ];

          # Lid switch bindings for clamshell mode
          # bindl = bindings that work even when screen is locked
          bindl = [
            ",switch:off:Lid Switch,exec,~/.config/hypr/lid.sh open"
            ",switch:on:Lid Switch,exec,~/.config/hypr/lid.sh close"
          ];

          # Startup applications
          exec-once = [
            "waybar" # Status bar
            "nm-applet --indicator" # NetworkManager applet for WiFi/network
            "blueman-applet" # Bluetooth applet
            "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1" # Polkit agent for password prompts
            "wl-paste --type text --watch cliphist store" # Clipboard manager
            "wl-paste --type image --watch cliphist store"
            "~/.local/bin/hypr-display-switcher.sh" # Initialize display state on login
          ];
        };
      };

      # Systemd user service for automatic display switching on monitor hotplug
      systemd.user.services.hypr-display-switcher = {
        Unit = {
          Description = "Auto enable/disable laptop screen on monitor hotplug";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${config.home.homeDirectory}/.local/bin/hypr-display-switcher.sh";
        };
      };

      # Enable and configure hypridle service
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener = [
            # Dim screen after 15 minutes
            {
              timeout = 900;
              on-timeout = "brightnessctl -s set 10";
              on-resume = "brightnessctl -r";
            }
            # Lock screen after 30 minutes
            {
              timeout = 1800;
              on-timeout = "loginctl lock-session";
            }
            # Turn off screen after 35 minutes
            {
              timeout = 2100;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
            # Suspend system after 60 minutes
            {
              timeout = 3600;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };

      # Copy keybindings help script and make it executable
      home.file.".config/hypr/keybinds-help.sh" = {
        source = ./hyprland-keybinds-help.sh;
        executable = true;
      };

      # Copy hyprlock configuration
      home.file.".config/hypr/hyprlock.conf" = {
        source = ./hyprlock.conf;
      };

      # Copy automatic display switcher script for udev hotplug
      home.file.".local/bin/hypr-display-switcher.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Auto enable/disable laptop screen based on number of monitors
          # Triggered by udev on monitor hotplug events

          BUILDIN_DISPLAY="eDP-1"
          DEFAULT_BUILDIN_ENABLE="eDP-1,1920x1080@60,auto,1.25"

          # Count number of active monitors
          num_of_monitors=$(hyprctl monitors all | grep "Monitor" | wc -l)

          if [[ $num_of_monitors -gt 1 ]]; then
            # Multiple monitors detected: disable laptop screen
            hyprctl keyword monitor "$BUILDIN_DISPLAY,disable"
            notify-send "Display Hotplug" "Laptop screen disabled - using external monitor"
          else
            # Single monitor: enable laptop screen
            hyprctl keyword monitor "$DEFAULT_BUILDIN_ENABLE"
            notify-send "Display Hotplug" "Laptop screen enabled"
          fi
        '';
        executable = true;
      };

      # Copy lid switch script for clamshell mode
      home.file.".config/hypr/lid.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Simple clamshell mode: close lid = disable laptop screen, open lid = enable laptop screen

          if [[ $1 == "open" ]]; then
            # Lid opened: enable laptop screen
            hyprctl dispatch dpms on eDP-1
            hyprctl keyword monitor "eDP-1,1920x1080@60,auto,1.25"
            notify-send "Laptop Screen" "Enabled"
          else
            # Lid closed: disable laptop screen
            hyprctl keyword monitor "eDP-1,disable"
            notify-send "Laptop Screen" "Disabled"
          fi
        '';
        executable = true;
      };

      # Copy display toggle script (manual override)
      home.file.".config/hypr/toggle-display.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Manual toggle for laptop screen (regardless of lid state)

          if hyprctl monitors | grep -q "eDP-1.*disabled: true"; then
            # Laptop is disabled, enable it
            hyprctl dispatch dpms on eDP-1
            hyprctl keyword monitor "eDP-1,1920x1080@60,auto,1.25"
            notify-send "Laptop Screen" "Enabled"
          else
            # Laptop is enabled, disable it
            hyprctl keyword monitor "eDP-1,disable"
            notify-send "Laptop Screen" "Disabled"
          fi
        '';
        executable = true;
      };

      # Install required packages for Hyprland ecosystem
      home.packages = with pkgs; [
        # Core Wayland tools
        waybar # Status bar
        rofi # Application launcher (Wayland support is now built-in)
        hyprshot # Wayland-native screenshot tool for Hyprland
        grim # Wayland screenshot tool (dependency for hyprshot)
        slurp # Select region tool (dependency for hyprshot)
        wl-clipboard # Clipboard utilities
        cliphist # Clipboard manager
        brightnessctl # Brightness control

        # Screen locking and idle management
        hyprlock # Hyprland's GPU-accelerated screen locker
        hypridle # Hyprland's idle daemon

        # Terminal - Wayland-native options
        foot # Lightweight Wayland terminal (primary)
        alacritty # Alternative Wayland terminal (backup)

        # Notification daemon
        mako

        # File manager
        xfce.thunar
        ffmpegthumbnailer # Video thumbnail support for Thunar

        # Network management
        networkmanagerapplet

        # Audio control
        pavucontrol

        # Bluetooth
        blueman

        # Password storage support
        libsecret # Secret Service API for password storage
        seahorse # GUI for managing passwords (optional but helpful)
      ];

      # Configure waybar
      programs.waybar = {
        enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 30;
            spacing = 4;

            modules-left = ["hyprland/workspaces" "hyprland/mode"];
            modules-center = ["hyprland/window"];
            modules-right = ["tray" "custom/nixos-updates" "disk" "pulseaudio" "battery" "clock"];

            "hyprland/workspaces" = {
              disable-scroll = true;
              all-outputs = true;
            };

            "hyprland/mode" = {
              format = "<span style=\"italic\">{}</span>";
            };

            "hyprland/window" = {
              format = "{}";
              max-length = 50;
            };

            clock = {
              timezone = "Europe/Copenhagen";
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
              format-alt = "{:%Y-%m-%d}";
            };

            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{capacity}% {icon}";
              format-charging = "{capacity}% ";
              format-plugged = "{capacity}% ";
              format-alt = "{time} {icon}";
              format-icons = ["" "" "" "" ""];
            };

            "custom/nixos-updates" = {
              exec = "nixos-update-checker";
              signal = 12;
              interval = 3600;
              tooltip = true;
              return-type = "json";
              format = "󰚰 {}";
              on-click = "nixos-update-checker";
            };

            disk = {
              interval = 30;
              format = "󰋊 {free}";
              path = "/";
              tooltip-format = "Used: {used} ({percentage_used}%)\nFree: {free} ({percentage_free}%)\nTotal: {total}";
              states = {
                warning = 20;
                critical = 10;
              };
            };

            pulseaudio = {
              format = "{volume}% {icon} {format_source}";
              format-bluetooth = "{volume}% {icon} {format_source}";
              format-bluetooth-muted = " {icon} {format_source}";
              format-muted = " {format_source}";
              format-source = "{volume}% ";
              format-source-muted = "";
              format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                phone = "";
                portable = "";
                car = "";
                default = ["" "" ""];
              };
              on-click = "pavucontrol";
            };

            tray = {
              icon-size = 21;
              spacing = 10;
            };
          };
        };
      };

      # Configure rofi for Wayland
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
        theme = "Arc-Dark";
        extraConfig = {
          modi = "drun,run,window";
          show-icons = true;
          drun-display-format = "{name}";
          disable-history = false;
          sidebar-mode = false;
        };
      };

      # Configure mako notifications
      services.mako = {
        enable = true;
        settings = {
          background-color = "#2e3440";
          border-color = "#5e81ac";
          text-color = "#eceff4";
          border-size = 2;
          border-radius = 5;
          default-timeout = 5000;
          max-visible = 3;
          # Enable history to store dismissed notifications
          max-history = 10; # Keep last 10 dismissed notifications
        };
      };

      # Set session variables for Wayland
      home.sessionVariables = {
        NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland
        MOZ_ENABLE_WAYLAND = "1"; # Enable Wayland for Firefox
        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";
        XDG_SESSION_TYPE = "wayland";
        WLR_NO_HARDWARE_CURSORS = "1"; # Fix cursor issues on some hardware
      };
    };
  }
