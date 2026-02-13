{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.niri;
in
  with lib; {
    # Note: niri home-manager module is already imported via the NixOS module
    # (inputs.niri.nixosModules.niri includes home-manager integration)

    options.mynix = {
      niri = {
        enable = mkEnableOption "Niri Scrollable Tiling Window Manager";
      };
    };

    config = mkIf cfg.enable {
      # niri-flake doesn't use enable option - just set settings directly
      programs.niri.settings = {
          # Input configuration
          input = {
            keyboard = {
              xkb = {
                layout = "dk";
              };
            };

            touchpad = {
              tap = true;
              natural-scroll = true;
              dwt = true; # disable-while-typing
            };

            mouse = {
              accel-speed = 0.0;
            };

            # Warp mouse cursor to focused window
            warp-mouse-to-focus = true;

            # Optional: focus follows mouse (only windows fully visible)
            # focus-follows-mouse.max-scroll-amount = "0%";
          };

          # Output/monitor configuration
          outputs = {
            # LG ULTRAGEAR+ ultrawide - native 5120x1440
            "DVI-I-1" = {
              mode = {
                width = 5120;
                height = 1440;
                refresh = 59.977;
              };
              position = { x = 0; y = 0; };
              scale = 1.25;
            };

            # Laptop screen
            "eDP-1" = {
              mode = {
                width = 1920;
                height = 1080;
                refresh = 60.0;
              };
              position = { x = 0; y = 1152; };  # Below external (1440/1.25 = 1152)
              scale = 1.25;
            };
          };

          # Layout configuration
          layout = {
            gaps = 10;
            center-focused-column = "always";

            preset-column-widths = [
              { proportion = 1.0 / 3.0; }
              { proportion = 1.0 / 2.0; }
              { proportion = 2.0 / 3.0; }
            ];

            default-column-width = { proportion = 1.0 / 2.0; };

            focus-ring = {
              enable = true;
              width = 2;
              active.color = "#33ccff";
              inactive.color = "#595959";
            };

            border = {
              enable = false;
            };
          };

          # Spawn at startup
          # Note: waybar removed - using eww sidebar instead (via systemd)
          spawn-at-startup = [
            { command = ["nm-applet" "--indicator"]; }
            { command = ["blueman-applet"]; }
            { command = ["/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1"]; }
            { command = ["wl-paste" "--type" "text" "--watch" "cliphist" "store"]; }
            { command = ["wl-paste" "--type" "image" "--watch" "cliphist" "store"]; }
            { command = ["sh" "-c" "~/.local/bin/niri-display-switcher.sh"]; }  # Initialize display state on login
          ];

          # Environment variables (set within Niri session)
          environment = {
            NIXOS_OZONE_WL = "1";
            MOZ_ENABLE_WAYLAND = "1";
            QT_QPA_PLATFORM = "wayland";
            SDL_VIDEODRIVER = "wayland";
            XDG_SESSION_TYPE = "wayland";
            WLR_NO_HARDWARE_CURSORS = "1";
          };

          # Cursor configuration
          cursor = {
            size = 24;
          };

          # Prefer server-side decorations
          prefer-no-csd = true;

          # Screenshot path
          screenshot-path = "/tmp/screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";

          # Hotkey overlay (help)
          hotkey-overlay = {
            skip-at-startup = true;
          };

          # Window rules
          window-rules = [
            {
              matches = [
                { app-id = "^pavucontrol$"; }
                { app-id = "^blueman-manager$"; }
                { app-id = "^nm-connection-editor$"; }
              ];
              open-floating = true;
            }
            {
              matches = [
                { title = "^Open File.*$"; }
                { title = "^Select a File.*$"; }
                { title = "^Save As.*$"; }
                { title = "^Open Folder.*$"; }
              ];
              open-floating = true;
            }
            # Messaging apps - 1/3 width
            {
              matches = [
                { app-id = "^[Ss]lack$"; }
                { app-id = "^[Ss]ignal$"; }
              ];
              default-column-width = { proportion = 1.0 / 3.0; };
            }
          ];

          # Keybindings (using niri-flake's attrset syntax)
          binds = {
            # Application launchers
            "Mod+Return".action.spawn = "kitty";
            "Mod+D".action.spawn = "fuzzel";
            "Mod+B".action.spawn = ["sh" "-c" "$BROWSER"];

            # Window management
            "Mod+W".action.close-window = [];
            "Mod+V".action.toggle-window-floating = [];
            "Mod+F".action.maximize-column = [];
            "Mod+Shift+F".action.fullscreen-window = [];

            # Focus movement - columns (horizontal)
            "Mod+H".action.focus-column-left = [];
            "Mod+L".action.focus-column-right = [];
            "Mod+Left".action.focus-column-left = [];
            "Mod+Right".action.focus-column-right = [];

            # Focus movement - within column, or workspace when at top/bottom
            "Mod+J".action.focus-window-or-workspace-down = [];
            "Mod+K".action.focus-window-or-workspace-up = [];
            "Mod+Down".action.focus-window-or-workspace-down = [];
            "Mod+Up".action.focus-window-or-workspace-up = [];

            # Move columns
            "Mod+Shift+H".action.move-column-left = [];
            "Mod+Shift+L".action.move-column-right = [];
            "Mod+Shift+Left".action.move-column-left = [];
            "Mod+Shift+Right".action.move-column-right = [];

            # Move windows within column
            "Mod+Shift+J".action.move-window-down = [];
            "Mod+Shift+K".action.move-window-up = [];
            "Mod+Shift+Down".action.move-window-down = [];
            "Mod+Shift+Up".action.move-window-up = [];

            # Workspace navigation (vertical infinite scroll)
            "Mod+U".action.focus-workspace-up = [];
            "Mod+I".action.focus-workspace-down = [];
            "Mod+Tab".action.focus-workspace-down = [];
            "Mod+Shift+Tab".action.focus-workspace-up = [];

            # Move window to workspace
            "Mod+Shift+U".action.move-window-to-workspace-up = [];
            "Mod+Shift+I".action.move-window-to-workspace-down = [];

            # Workspace by number
            "Mod+1".action.focus-workspace = 1;
            "Mod+2".action.focus-workspace = 2;
            "Mod+3".action.focus-workspace = 3;
            "Mod+4".action.focus-workspace = 4;
            "Mod+5".action.focus-workspace = 5;
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;

            "Mod+Shift+1".action.move-window-to-workspace = 1;
            "Mod+Shift+2".action.move-window-to-workspace = 2;
            "Mod+Shift+3".action.move-window-to-workspace = 3;
            "Mod+Shift+4".action.move-window-to-workspace = 4;
            "Mod+Shift+5".action.move-window-to-workspace = 5;
            "Mod+Shift+6".action.move-window-to-workspace = 6;
            "Mod+Shift+7".action.move-window-to-workspace = 7;
            "Mod+Shift+8".action.move-window-to-workspace = 8;
            "Mod+Shift+9".action.move-window-to-workspace = 9;

            # Column sizing
            "Mod+Ctrl+H".action.set-column-width = "-10%";
            "Mod+Ctrl+L".action.set-column-width = "+10%";
            "Mod+M".action.maximize-column = [];
            "Mod+R".action.switch-preset-column-width = [];

            # Window height
            "Mod+Ctrl+J".action.set-window-height = "+10%";
            "Mod+Ctrl+K".action.set-window-height = "-10%";

            # Consume/expel windows from column
            "Mod+Comma".action.consume-window-into-column = [];
            "Mod+Period".action.expel-window-from-column = [];

            # System controls
            "Mod+Escape".action.spawn = ["swaylock" "-f" "-c" "000000"];
            "Mod+Shift+Q".action.spawn = ["sh" "-c" "systemctl --user start niri-session-quit.service"];
            "Mod+Shift+Slash".action.show-hotkey-overlay = [];
            "Mod+Minus".action.show-hotkey-overlay = [];

            # Display toggle - Super+Shift+Escape to toggle laptop screen
            "Mod+Shift+Escape".action.spawn = ["sh" "-c" "~/.local/bin/niri-toggle-display.sh"];

            # Overview mode (GNOME-like workspace overview)
            "Mod+Space".action.toggle-overview = [];

            # Screenshots
            "Print".action.screenshot = [];
            "Mod+Print".action.spawn = ["sh" "-c" "grim -o $(niri msg focused-output) /tmp/screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png"];
            "Mod+Shift+Print".action.spawn = ["sh" "-c" "grim -g \"$(slurp)\" /tmp/screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png"];

            # Volume control
            "XF86AudioRaiseVolume".action.spawn = ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"];
            "XF86AudioLowerVolume".action.spawn = ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"];
            "XF86AudioMute".action.spawn = ["sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"];

            # Brightness control
            "XF86MonBrightnessUp".action.spawn = ["sh" "-c" "brightnessctl set 10%+"];
            "XF86MonBrightnessDown".action.spawn = ["sh" "-c" "brightnessctl set 10%-"];

            # Notification management
            "Mod+N".action.spawn = ["sh" "-c" "makoctl restore"];
            "Mod+Shift+N".action.spawn = ["sh" "-c" "makoctl dismiss --all"];

            # Mouse bindings for workspace scrolling
            "Mod+WheelScrollDown".action.focus-workspace-down = [];
            "Mod+WheelScrollDown".cooldown-ms = 150;
            "Mod+WheelScrollUp".action.focus-workspace-up = [];
            "Mod+WheelScrollUp".cooldown-ms = 150;
          };
        };

      # Enable and configure swayidle service
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 900;
            command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
            resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
          {
            timeout = 1800;
            command = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
          }
          {
            timeout = 2100;
            command = "niri msg action power-off-monitors";
            resumeCommand = "niri msg action power-on-monitors";
          }
        ];
        events = [
          {
            event = "before-sleep";
            command = "sh -c '${config.home.homeDirectory}/.local/bin/save-terminal-session; ${pkgs.swaylock}/bin/swaylock -f -c 000000'";
          }
        ];
      };

      # Install required packages for Niri ecosystem
      home.packages = with pkgs; [
        # Core Wayland tools
        waybar
        fuzzel
        grim
        slurp
        jq
        wl-clipboard
        cliphist
        brightnessctl

        # Screen locking
        swaylock

        # Terminal (backup options, kitty managed by kitty.nix)
        foot
        alacritty

        # Notification daemon
        mako

        # File manager
        thunar
        ffmpegthumbnailer

        # Network management
        networkmanagerapplet

        # Audio control
        pavucontrol

        # Bluetooth
        blueman

        # Password storage support
        libsecret
        seahorse
      ];

      # Note: waybar is configured in hyprland.nix - it works with both WMs
      # To use niri-specific modules, adjust the hyprland waybar config

      # Configure fuzzel launcher
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            terminal = "kitty";
            layer = "overlay";
            width = 50;
            font = "monospace:size=12";
          };
          colors = {
            background = "2e3440ff";
            text = "eceff4ff";
            selection = "5e81acff";
            selection-text = "eceff4ff";
            border = "5e81acff";
          };
          border = {
            width = 2;
            radius = 5;
          };
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
          max-history = 10;
        };
      };

      # Session variables also set globally for apps launched outside Niri
      # (the niri.settings.environment covers the Niri session itself)
      home.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";
        XDG_SESSION_TYPE = "wayland";
        WLR_NO_HARDWARE_CURSORS = "1";
      };

      # Session save script - stores app placement + terminal cwd state
      home.file.".local/bin/save-terminal-session" = {
        text = ''
          #!/usr/bin/env bash
          set -u
          set -o pipefail

          STATE_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/niri/session.json"
          STATE_DIR="$(dirname "$STATE_FILE")"

          log() {
            printf '[save-terminal-session] %s\n' "$*" >&2
          }

          fetch_json() {
            local what="$1"
            local out
            out=$(niri msg --json "$what" 2>/dev/null || true)
            if jq -e . >/dev/null 2>&1 <<<"$out"; then
              printf '%s\n' "$out"
            else
              printf '[]\n'
            fi
          }

          get_cwd_from_pid() {
            local pid="$1"
            if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
              readlink -f "/proc/$pid/cwd" 2>/dev/null || true
            fi
          }

          mkdir -p "$STATE_DIR" || {
            log "failed to create state directory"
            exit 1
          }

          windows_json=$(fetch_json windows)
          workspaces_json=$(fetch_json workspaces)

          base_json=$(jq -n \
            --argjson windows "$windows_json" \
            --argjson workspaces "$workspaces_json" '
            def to_num:
              if type == "number" then .
              elif type == "string" and test("^-?[0-9]+$") then tonumber
              else 0 end;

            def workspace_idx_for($ws_id):
              ([($workspaces // [])[] | select((.id // null) == $ws_id) | (.idx // 0)] | .[0]) // 0;

            {
              schema_version: 1,
              saved_at: (now | todateiso8601),
              windows: [
                ($windows // [])[] | {
                  app_id: (.app_id // ""),
                  title: (.title // ""),
                  workspace_id: (.workspace_id // null),
                  workspace_idx: workspace_idx_for(.workspace_id),
                  column_idx: ((.layout.pos_in_scrolling_layout[0] // 0) | to_num),
                  is_focused: (.is_focused // false),
                  is_floating: (.is_floating // false),
                  pid: (.pid // null)
                }
              ]
            }
          ')

          windows_with_terminal_state="[]"
          while IFS= read -r row; do
            pid=$(jq -r '.pid // ""' <<<"$row")
            app_id=$(jq -r '.app_id // ""' <<<"$row")
            if [[ "$app_id" == "kitty" ]]; then
              cwd=$(get_cwd_from_pid "$pid")
              windows_with_terminal_state=$(jq \
                --argjson row "$row" \
                --arg cwd "$cwd" \
                '. + [($row + {terminal_state: {emulator: "kitty", cwd: $cwd}})]' \
                <<<"$windows_with_terminal_state")
            else
              windows_with_terminal_state=$(jq --argjson row "$row" '. + [$row]' <<<"$windows_with_terminal_state")
            fi
          done < <(jq -c '.windows[]?' <<<"$base_json")

          session_json=$(jq --argjson windows "$windows_with_terminal_state" '.windows = $windows' <<<"$base_json")

          tmp_file=$(mktemp "$STATE_FILE.tmp.XXXXXX")
          printf '%s\n' "$session_json" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
          log "saved $(jq -r '.windows | length' <<<"$session_json") windows to $STATE_FILE"
        '';
        executable = true;
      };

      # Session restore script - restores app placement + terminal cwd
      home.file.".local/bin/restore-terminal-session" = {
        text = ''
          #!/usr/bin/env bash
          set -u
          set -o pipefail

          STATE_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/niri/session.json"

          log() {
            printf '[restore-terminal-session] %s\n' "$*" >&2
          }

          wait_for_niri_ipc() {
            local attempts=80
            local delay=0.15
            local i out

            for ((i=1; i<=attempts; i++)); do
              out=$(niri msg --json workspaces 2>/dev/null || true)
              if jq -e . >/dev/null 2>&1 <<<"$out"; then
                return 0
              fi
              sleep "$delay"
            done

            return 1
          }

          command_for_app_id() {
            local app_id="$1"
            local lower="''${app_id,,}"

            case "$lower" in
              firefox*) echo "firefox" ;;
              zen*) echo "zen" ;;
              org.wezfurlong.wezterm|wezterm*) echo "wezterm" ;;
              code-oss|com.visualstudio.code.oss|vscode|code) echo "code-oss" ;;
              com.mitchellh.ghostty|ghostty*) echo "ghostty" ;;
              slack*) echo "slack" ;;
              signal*|org.signal.signal*) echo "signal-desktop" ;;
              spotify*) echo "spotify" ;;
              obsidian*) echo "obsidian" ;;
              thunar*) echo "thunar" ;;
              pavucontrol*) echo "pavucontrol" ;;
              blueman-manager*|org.blueman.manager*) echo "blueman-manager" ;;
              *discord*|com.discordapp.discord*) echo "discord" ;;
              *) echo "$app_id" ;;
            esac
          }

          focus_workspace() {
            local idx="$1"
            [[ -n "$idx" ]] || return 1
            niri msg action focus-workspace "$idx" >/dev/null 2>&1
          }

          spawn_command() {
            local cmd="$1"
            niri msg action spawn -- sh -lc "$cmd" >/dev/null 2>&1 || true
          }

          restore_windows() {
            local list_json="$1"
            local last_ws=""
            while IFS= read -r win; do
              [[ -n "$win" ]] || continue
              ws_idx=$(jq -r '.resolved_workspace_idx // 1' <<<"$win")
              app_id=$(jq -r '.app_id // ""' <<<"$win")

              if [[ "$ws_idx" != "$last_ws" ]]; then
                focus_workspace "$ws_idx" || log "failed to focus workspace $ws_idx"
                last_ws="$ws_idx"
                sleep 0.05
              fi

              if [[ "$app_id" == "kitty" ]]; then
                cwd=$(jq -r '.terminal_state.cwd // ""' <<<"$win")
                if [[ -n "$cwd" ]]; then
                  printf -v qcwd '%q' "$cwd"
                  spawn_command "kitty --directory $qcwd"
                else
                  spawn_command "kitty"
                fi
              else
                cmd=$(command_for_app_id "$app_id")
                [[ -n "$cmd" ]] && spawn_command "$cmd"
              fi
              sleep 0.05
            done <<<"$list_json"
          }

          [[ -f "$STATE_FILE" ]] || exit 0
          jq -e '.schema_version == 1' "$STATE_FILE" >/dev/null 2>&1 || exit 0
          wait_for_niri_ipc || exit 0

          current_workspaces=$(niri msg --json workspaces 2>/dev/null || printf '[]')

          ordered_windows=$(jq -c --argjson current "$current_workspaces" '
            def workspace_idx_from_id($ws_id):
              ([($current // [])[] | select((.id // null) == $ws_id) | (.idx // 0)] | .[0]);

            [(.windows // [])[]
              | . + {
                resolved_workspace_idx: (
                  workspace_idx_from_id(.workspace_id) // (.workspace_idx // 1)
                )
              }
            ]
            | sort_by(.resolved_workspace_idx, .column_idx)
            | .[]
          ' "$STATE_FILE")

          non_terminal_windows=$(jq -c 'select((.app_id // "") != "kitty")' <<<"$ordered_windows")
          terminal_windows=$(jq -c 'select((.app_id // "") == "kitty")' <<<"$ordered_windows")

          restore_windows "$non_terminal_windows"
          restore_windows "$terminal_windows"
        '';
        executable = true;
      };

      # Display switcher script - auto enable/disable laptop screen on hotplug
      home.file.".local/bin/niri-display-switcher.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Auto enable/disable laptop screen based on number of monitors
          # Triggered on login and by udev on monitor hotplug events

          BUILTIN_DISPLAY="eDP-1"

          # Small delay to let niri detect the display change
          sleep 1

          # Count outputs using stable JSON output
          output_count=$(niri msg --json outputs 2>/dev/null | jq 'length' 2>/dev/null || echo 0)

          # If we have more than 1 output total (laptop + external), external is connected
          if [[ $output_count -gt 1 ]]; then
            # External monitor detected: disable laptop screen
            niri msg output "$BUILTIN_DISPLAY" off 2>/dev/null
            notify-send "Display Hotplug" "Laptop screen disabled - using external monitor"
          else
            # No external monitor: enable laptop screen
            niri msg output "$BUILTIN_DISPLAY" on 2>/dev/null
            notify-send "Display Hotplug" "Laptop screen enabled"
          fi
        '';
        executable = true;
      };

      # Display toggle script - manual override for laptop screen
      home.file.".local/bin/niri-toggle-display.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Manual toggle for laptop screen (regardless of lid state)

          BUILTIN_DISPLAY="eDP-1"

          # Check if eDP-1 is currently off using stable JSON output
          if niri msg --json outputs 2>/dev/null | jq -e --arg output "$BUILTIN_DISPLAY" '.[] | select(.name == $output and ((.current_mode // null) == null))' >/dev/null 2>&1; then
            # Laptop is disabled, enable it
            niri msg output "$BUILTIN_DISPLAY" on 2>/dev/null
            notify-send "Laptop Screen" "Enabled"
          else
            # Laptop is enabled, disable it
            niri msg output "$BUILTIN_DISPLAY" off 2>/dev/null
            notify-send "Laptop Screen" "Disabled"
          fi
        '';
        executable = true;
      };

      # Systemd user service for automatic display switching on monitor hotplug
      systemd.user.services.niri-display-switcher = {
        Unit = {
          Description = "Auto enable/disable laptop screen on monitor hotplug (Niri)";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${config.home.homeDirectory}/.local/bin/niri-display-switcher.sh";
        };
      };

      systemd.user.services.niri-session-save = {
        Unit = {
          Description = "Save Niri session state";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${config.home.homeDirectory}/.local/bin/save-terminal-session";
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };

      systemd.user.timers.niri-session-save = {
        Unit = {
          Description = "Periodically save Niri session state";
        };
        Timer = {
          OnBootSec = "2m";
          OnUnitActiveSec = "2m";
          Unit = "niri-session-save.service";
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };

      systemd.user.services.niri-session-restore = {
        Unit = {
          Description = "Restore Niri session state";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target" "niri-display-switcher.service"];
          Wants = ["graphical-session.target" "niri-display-switcher.service"];
          ConditionPathExists = "%h/.local/state/niri/session.json";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${config.home.homeDirectory}/.local/bin/restore-terminal-session";
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };

      systemd.user.services.niri-session-quit = {
        Unit = {
          Description = "Save Niri session and quit";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "sh -c '${config.home.homeDirectory}/.local/bin/save-terminal-session && niri msg action quit'";
        };
      };
    };
  }
