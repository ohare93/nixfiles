{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.eww;
in
  with lib; {
    options.mynix = {
      eww = {
        enable = mkEnableOption "eww sidebar for niri";
      };
    };

    config = mkIf cfg.enable {
      # Install eww and dependencies
      # Note: python3 not added here to avoid conflicts with other python environments
      # The daemon uses #!/usr/bin/env python3 which finds system python
      home.packages = with pkgs; [
        eww
        jq
        lm_sensors # for temperature readings
        wireplumber # for wpctl in system-stats
        libnotify # for notify-send in toggle scripts
      ];

      # eww configuration files
      xdg.configFile."eww/eww.yuck".source = ./eww/eww.yuck;
      xdg.configFile."eww/eww.scss".source = ./eww/eww.scss;

      # Scripts
      home.file.".local/bin/niri-eww-daemon" = {
        text = ''
          #!/usr/bin/env python3
          """
          Niri event-stream daemon for eww.
          Listens to niri IPC and outputs JSON for eww deflisten.
          """
          import json
          import subprocess
          import sys
          import signal

          # App ID to icon mapping
          APP_ICONS = {
              "firefox": "firefox",
              "org.mozilla.firefox": "firefox",
              "kitty": "utilities-terminal",
              "foot": "utilities-terminal",
              "alacritty": "utilities-terminal",
              "code": "visual-studio-code",
              "Code": "visual-studio-code",
              "code-url-handler": "visual-studio-code",
              "thunar": "system-file-manager",
              "nautilus": "system-file-manager",
              "org.gnome.Nautilus": "system-file-manager",
              "spotify": "spotify",
              "Spotify": "spotify",
              "discord": "discord",
              "Discord": "discord",
              "slack": "slack",
              "Slack": "slack",
              "signal": "signal",
              "Signal": "signal",
              "telegram-desktop": "telegram",
              "org.telegram.desktop": "telegram",
              "chromium": "chromium",
              "google-chrome": "google-chrome",
              "brave-browser": "brave",
              "pavucontrol": "audio-volume-high",
              "blueman-manager": "bluetooth",
              "nm-connection-editor": "network-wireless",
              "eog": "image-viewer",
              "org.gnome.eog": "image-viewer",
              "evince": "document-viewer",
              "org.gnome.Evince": "document-viewer",
              "zathura": "document-viewer",
              "gimp": "gimp",
              "inkscape": "inkscape",
              "libreoffice": "libreoffice-main",
              "obsidian": "obsidian",
              "steam": "steam",
              "vlc": "vlc",
              "mpv": "mpv",
          }

          def get_icon(app_id):
              """Map app_id to icon name."""
              if not app_id:
                  return "application-x-executable"
              # Try direct match
              if app_id in APP_ICONS:
                  return APP_ICONS[app_id]
              # Try lowercase
              app_lower = app_id.lower()
              if app_lower in APP_ICONS:
                  return APP_ICONS[app_lower]
              # Try partial match
              for key, icon in APP_ICONS.items():
                  if key.lower() in app_lower or app_lower in key.lower():
                      return icon
              return "application-x-executable"

          class NiriState:
              def __init__(self):
                  self.workspaces = {}  # idx -> workspace data
                  self.windows = {}     # window_id -> window data
                  self.focused_workspace = None
                  self.focused_window = None
                  self.initialize()

              def initialize(self):
                  """Get initial state from niri."""
                  try:
                      # Get workspaces
                      result = subprocess.run(
                          ["niri", "msg", "-j", "workspaces"],
                          capture_output=True, text=True, timeout=5
                      )
                      if result.returncode == 0:
                          ws_list = json.loads(result.stdout)
                          for ws in ws_list:
                              idx = ws.get("idx", ws.get("id"))
                              self.workspaces[idx] = {
                                  "id": ws.get("id"),
                                  "idx": idx,
                                  "is_focused": ws.get("is_focused", False),
                                  "is_active": ws.get("is_active", False),
                                  "output": ws.get("output", ""),
                                  "windows": []
                              }
                              if ws.get("is_focused"):
                                  self.focused_workspace = idx

                      # Get windows
                      result = subprocess.run(
                          ["niri", "msg", "-j", "windows"],
                          capture_output=True, text=True, timeout=5
                      )
                      if result.returncode == 0:
                          win_list = json.loads(result.stdout)
                          for win in win_list:
                              win_id = win.get("id")
                              ws_id = win.get("workspace_id")  # This is workspace id, not idx
                              app_id = win.get("app_id", "")
                              self.windows[win_id] = {
                                  "id": win_id,
                                  "app_id": app_id,
                                  "title": win.get("title", ""),
                                  "workspace_id": ws_id,
                                  "is_focused": win.get("is_focused", False),
                                  "icon": get_icon(app_id)
                              }
                              if win.get("is_focused"):
                                  self.focused_window = win_id
                              # Add to workspace windows (find by id, not idx)
                              for workspace in self.workspaces.values():
                                  if workspace["id"] == ws_id:
                                      workspace["windows"].append({
                                          "id": win_id,
                                          "app_id": app_id,
                                          "icon": get_icon(app_id)
                                      })
                                      break
                  except Exception as e:
                      print(f"Init error: {e}", file=sys.stderr)

              def handle_event(self, event):
                  """Handle a niri event and return True if state changed."""
                  event_type = list(event.keys())[0] if event else None
                  if not event_type:
                      return False

                  data = event.get(event_type, {})

                  if event_type == "WorkspacesChanged":
                      workspaces = data.get("workspaces", [])
                      # Rebuild workspace list, preserving window info
                      old_windows = {idx: ws.get("windows", []) for idx, ws in self.workspaces.items()}
                      self.workspaces = {}
                      for ws in workspaces:
                          idx = ws.get("idx", ws.get("id"))
                          self.workspaces[idx] = {
                              "id": ws.get("id"),
                              "idx": idx,
                              "is_focused": ws.get("is_focused", False),
                              "is_active": ws.get("is_active", False),
                              "output": ws.get("output", ""),
                              "windows": old_windows.get(idx, [])
                          }
                          if ws.get("is_focused"):
                              self.focused_workspace = idx
                      return True

                  elif event_type == "WorkspaceActivated":
                      ws_id = data.get("id")
                      focused = data.get("focused", False)
                      # Find workspace by id
                      for idx, ws in self.workspaces.items():
                          if ws["id"] == ws_id:
                              ws["is_active"] = True
                              if focused:
                                  # Unfocus all others first
                                  for other in self.workspaces.values():
                                      other["is_focused"] = False
                                  ws["is_focused"] = True
                                  self.focused_workspace = idx
                      return True

                  elif event_type == "WindowOpenedOrChanged":
                      win = data.get("window", {})
                      win_id = win.get("id")
                      ws_id = win.get("workspace_id")
                      app_id = win.get("app_id", "")

                      # Track old workspace if window exists (for movement detection)
                      old_ws_id = None
                      if win_id in self.windows:
                          old_ws_id = self.windows[win_id].get("workspace_id")

                      self.windows[win_id] = {
                          "id": win_id,
                          "app_id": app_id,
                          "title": win.get("title", ""),
                          "workspace_id": ws_id,
                          "is_focused": win.get("is_focused", False),
                          "icon": get_icon(app_id)
                      }

                      # Handle window move: remove from old workspace if different
                      if old_ws_id and old_ws_id != ws_id:
                          for ws in self.workspaces.values():
                              if ws["id"] == old_ws_id:
                                  ws["windows"] = [w for w in ws["windows"] if w["id"] != win_id]
                                  break

                      # Add to new workspace if new or moved
                      if old_ws_id is None or old_ws_id != ws_id:
                          for idx, workspace in self.workspaces.items():
                              if workspace["id"] == ws_id:
                                  workspace["windows"].append({
                                      "id": win_id,
                                      "app_id": app_id,
                                      "icon": get_icon(app_id)
                                  })
                                  break
                      return True

                  elif event_type == "WindowClosed":
                      win_id = data.get("id")
                      if win_id in self.windows:
                          # Remove from workspace windows
                          win_ws = self.windows[win_id].get("workspace_id")
                          for ws in self.workspaces.values():
                              if ws["id"] == win_ws:
                                  ws["windows"] = [w for w in ws["windows"] if w["id"] != win_id]
                          del self.windows[win_id]
                          if self.focused_window == win_id:
                              self.focused_window = None
                      return True

                  elif event_type == "WindowFocusChanged":
                      win_id = data.get("id")
                      # Update focus states
                      for w in self.windows.values():
                          w["is_focused"] = (w["id"] == win_id)
                      self.focused_window = win_id
                      return True

                  return False

              def to_json(self):
                  """Output current state as JSON."""
                  # Sort workspaces by idx
                  ws_list = []
                  for idx in sorted(self.workspaces.keys()):
                      ws = self.workspaces[idx]
                      ws_list.append({
                          "id": ws["id"],
                          "idx": idx,
                          "is_focused": ws["is_focused"],
                          "is_active": ws["is_active"],
                          "windows": ws["windows"]
                      })

                  return json.dumps({
                      "workspaces": ws_list,
                      "focused_workspace": self.focused_workspace,
                      "focused_window": self.focused_window
                  })

          def main():
              state = NiriState()

              # Output initial state
              print(state.to_json(), flush=True)

              # Handle SIGTERM gracefully
              def handle_signal(signum, frame):
                  sys.exit(0)
              signal.signal(signal.SIGTERM, handle_signal)
              signal.signal(signal.SIGINT, handle_signal)

              # Listen to event stream
              try:
                  proc = subprocess.Popen(
                      ["niri", "msg", "-j", "event-stream"],
                      stdout=subprocess.PIPE,
                      stderr=subprocess.DEVNULL,
                      text=True,
                      bufsize=1
                  )

                  for line in proc.stdout:
                      line = line.strip()
                      if not line:
                          continue
                      try:
                          event = json.loads(line)
                          if state.handle_event(event):
                              print(state.to_json(), flush=True)
                      except json.JSONDecodeError:
                          continue

              except Exception as e:
                  print(f"Error: {e}", file=sys.stderr)
                  sys.exit(1)

          if __name__ == "__main__":
              main()
        '';
        executable = true;
      };

      home.file.".local/bin/eww-system-stats" = {
        text = ''
          #!/usr/bin/env bash
          # Output system stats as JSON for eww polling

          # CPU usage (percentage)
          cpu=$(awk '/^cpu / {usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f", usage}' /proc/stat)

          # Memory usage (percentage)
          mem=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')

          # Temperature (from sensors - supports Intel Core and AMD Tctl)
          temp=$(sensors 2>/dev/null | awk '/^Core 0:|^Tctl:/ {gsub(/[+°C]/,""); print $2; exit}')
          if [[ -z "$temp" ]]; then
              # Fallback to thermal zone
              temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
              temp=$((temp / 1000))
          fi
          temp=''${temp:-50}

          # Disk usage (root partition percentage)
          disk=$(df / | awk 'NR==2 {gsub(/%/,""); print $5}')

          # Volume (percentage, muted status)
          vol_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
          vol=$(echo "$vol_info" | awk '{printf "%.0f", $2*100}')
          muted=$(echo "$vol_info" | grep -q MUTED && echo "true" || echo "false")

          # Battery (auto-detect BAT0/BAT1/etc)
          bat_path=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
          if [[ -n "$bat_path" ]]; then
              bat_cap=$(cat "$bat_path/capacity" 2>/dev/null || echo "100")
              bat_status=$(cat "$bat_path/status" 2>/dev/null || echo "Unknown")
          else
              bat_cap=100
              bat_status="Unknown"
          fi

          # WiFi status
          wifi_enabled=$(nmcli radio wifi 2>/dev/null || echo "disabled")
          wifi_enabled=$([[ "$wifi_enabled" == "enabled" ]] && echo "true" || echo "false")
          wifi_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2)

          # Bluetooth status
          bt_powered=$(bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo "true" || echo "false")

          # Night light (hyprsunset service)
          nightlight=$(systemctl --user is-active hyprsunset.service 2>/dev/null)
          nightlight=$([[ "$nightlight" == "active" ]] && echo "true" || echo "false")

          # Caffeine (check for systemd-inhibit)
          caffeine_pid_file="''${XDG_RUNTIME_DIR:-/tmp}/eww-caffeine.pid"
          caffeine=$([[ -f "$caffeine_pid_file" ]] && kill -0 $(cat "$caffeine_pid_file") 2>/dev/null && echo "true" || echo "false")

          # Output JSON (no leading whitespace)
          printf '{"cpu":%d,"mem":%d,"temp":%d,"disk":%d,"volume":%d,"muted":%s,"battery":%d,"battery_status":"%s","wifi_enabled":%s,"wifi_ssid":"%s","bluetooth":%s,"nightlight":%s,"caffeine":%s}\n' \
            "$cpu" "$mem" "$temp" "$disk" "$vol" "$muted" "$bat_cap" "$bat_status" "$wifi_enabled" "$wifi_ssid" "$bt_powered" "$nightlight" "$caffeine"
        '';
        executable = true;
      };

      home.file.".local/bin/eww-wifi-toggle" = {
        text = ''
          #!/usr/bin/env bash
          current=$(nmcli radio wifi)
          if [[ "$current" == "enabled" ]]; then
              nmcli radio wifi off
          else
              nmcli radio wifi on
          fi
        '';
        executable = true;
      };

      home.file.".local/bin/eww-bluetooth-toggle" = {
        text = ''
          #!/usr/bin/env bash
          powered=$(bluetoothctl show | grep -q "Powered: yes" && echo "yes" || echo "no")
          if [[ "$powered" == "yes" ]]; then
              bluetoothctl power off
          else
              bluetoothctl power on
          fi
        '';
        executable = true;
      };

      home.file.".local/bin/eww-caffeine-toggle" = {
        text = ''
          #!/usr/bin/env bash
          PID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/eww-caffeine.pid"

          if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
              # Caffeine is on, turn it off
              kill $(cat "$PID_FILE") 2>/dev/null
              rm -f "$PID_FILE"
              notify-send "Caffeine" "Disabled - idle/sleep inhibitors removed"
          else
              # Caffeine is off, turn it on
              systemd-inhibit --what=idle:sleep --who="eww-caffeine" --why="User requested" sleep infinity &
              echo $! > "$PID_FILE"
              notify-send "Caffeine" "Enabled - preventing idle and sleep"
          fi
        '';
        executable = true;
      };

      home.file.".local/bin/eww-nightlight-toggle" = {
        text = ''
          #!/usr/bin/env bash
          if systemctl --user is-active hyprsunset.service >/dev/null 2>&1; then
              systemctl --user stop hyprsunset.service
              notify-send "Night Light" "Disabled"
          else
              systemctl --user start hyprsunset.service
              notify-send "Night Light" "Enabled"
          fi
        '';
        executable = true;
      };

      # Systemd service to run eww daemon
      systemd.user.services.eww = {
        Unit = {
          Description = "Eww Daemon";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };

      # Open the sidebar when eww starts
      systemd.user.services.eww-sidebar = {
        Unit = {
          Description = "Eww Sidebar";
          After = ["eww.service"];
          Requires = ["eww.service"];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          # Small delay to ensure eww daemon socket is ready
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
          ExecStart = "${pkgs.eww}/bin/eww open sidebar";
          ExecStop = "${pkgs.eww}/bin/eww close sidebar";
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  }
