{
  lib,
  config,
  pkgs,
  inputs,
  hostname,
  ...
}: let
  cfg = config.mynix.gui-software;
in
  with lib; {
    options.mynix = {
      gui-software = {
        enable = mkEnableOption "GUI Software";
      };
    };

    config = mkIf cfg.enable {
      # Enable qutebrowser with custom configuration
      mynix.qutebrowser.enable = true;

      # Enable Firefox with Tridactyl and set as default browser
      mynix.firefox = {
        enable = true;
        defaultBrowser = true;
      };

      # PDF viewer with clipboard support
      programs.zathura = {
        enable = true;
        options = {
          selection-clipboard = "clipboard";
        };
      };

      # Configure ungoogled-chromium with Browser MCP extension
      programs.chromium = {
        enable = true;
        package = pkgs.ungoogled-chromium;
        extensions = [
          {id = "bjfgambnhccakkhmkepdoekmckoijdlc";} # Browser MCP extension
        ];
      };

      # Configure agenix to use our SSH key
      age.identityPaths = ["${config.home.homeDirectory}/.ssh/age_${hostname}"];

      # Define the ntfy token secret
      age.secrets.ntfy-token = {
        file = ../../secrets/ntfy-token.age;
        mode = "400";
      };

      home.packages = with pkgs; [
        wireguard-ui
        bitwarden-desktop
        plexamp
        keymapp
        signal-desktop
        telegram-desktop
        logseq
        zotero
        showmethekey
        caffeine-ng # Prevent screen sleep/lock
        libnotify
        ntfy-sh

        # Speech-to-text
        openai-whisper
        wl-clipboard
        ffmpeg

        # Office documents
        libreoffice
        poppler-utils # pdftoppm for yazi office preview
      ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          # PDF viewer - zathura as default
          "application/pdf" = "org.pwmt.zathura.desktop";

          # Application-specific URL schemes
          "x-scheme-handler/bitwarden" = "bitwarden.desktop";
          "x-scheme-handler/abc" = "Plexamp.desktop";
          "x-scheme-handler/sgnl" = "signal.desktop";
          "x-scheme-handler/signalcaptcha" = "signal.desktop";
          "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
          "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
          "x-scheme-handler/logseq" = "Logseq.desktop";
        };
      };

      # Speech-to-text script
      home.file.".local/bin/stt" = {
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          # Configuration
          TEMP_AUDIO="/tmp/stt_recording.wav"
          DURATION=''${1:-10}  # Default 10 seconds, or pass duration as argument

          # Notify start
          notify-send "Speech-to-Text" "Recording for $DURATION seconds..."

          # Record audio
          ffmpeg -f pulse -i default -t "$DURATION" -ar 16000 -ac 1 "$TEMP_AUDIO" -y 2>/dev/null

          # Notify processing
          notify-send "Speech-to-Text" "Transcribing..."

          # Transcribe with whisper
          TRANSCRIPTION=$(whisper "$TEMP_AUDIO" --model tiny --language English --output_format txt --output_dir /tmp 2>/dev/null)

          # Get the output file (whisper creates a .txt file)
          TEXT_FILE="/tmp/$(basename "$TEMP_AUDIO" .wav).txt"

          if [ -f "$TEXT_FILE" ]; then
            # Copy to clipboard
            wl-copy < "$TEXT_FILE"
            notify-send "Speech-to-Text" "Transcription copied to clipboard!"

            # Clean up
            rm -f "$TEMP_AUDIO" "$TEXT_FILE"
          else
            notify-send "Speech-to-Text" "Transcription failed!"
            rm -f "$TEMP_AUDIO"
            exit 1
          fi
        '';
        executable = true;
      };

      # Link handler script for ntfy linkshare notifications
      home.file.".local/bin/ntfy-linkshare" = {
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          TITLE="$1"
          MESSAGE="$2"
          LOG_DIR="${config.home.homeDirectory}/.local/share/ntfy"
          LOG_FILE="$LOG_DIR/linkshare.log"

          # Create log directory if it doesn't exist
          mkdir -p "$LOG_DIR"

          # Log the message with timestamp
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] $TITLE: $MESSAGE" >> "$LOG_FILE"

          # Extract all URLs from the message
          URLS=$(echo "$MESSAGE" | grep -oE 'https?://[^ ]+' || true)

          # Open each URL in the browser
          if [ -n "$URLS" ]; then
            while IFS= read -r URL; do
              $BROWSER "$URL" &
            done <<< "$URLS"
          fi

          # Always show the full message as a notification
          ${pkgs.libnotify}/bin/notify-send -t 10000 "$TITLE" "$MESSAGE"
        '';
        executable = true;
      };

      # Command to manually refetch ntfy messages from a specific time
      home.file.".local/bin/ntfy-refetch" = {
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          # Default to 1 hour if no argument provided
          SINCE="''${1:-1h}"

          echo "Fetching ntfy messages since: $SINCE"
          echo "Supported formats: 10m, 2h, 30s, Unix timestamp, 'all', or 'latest'"
          echo ""

          TOKEN=$(cat ${config.age.secrets.ntfy-token.path})
          ${pkgs.ntfy-sh}/bin/ntfy sub --from-config --token "$TOKEN" --poll --since "$SINCE"

          echo ""
          echo "Done! Any links have been opened in your browser."
        '';
        executable = true;
      };

      # Configure Konsole to disable menu accelerators and hide problematic UI elements
      home.file.".config/konsolerc".text = ''
        [KonsoleWindow]
        ShowMenuBarByDefault=false

        [MainWindow]
        MenuBar=Disabled
        ToolBarsMovable=Disabled

        [General]
        EnableMenuAccelerators=false

        [TabBar]
        TabBarVisibility=ShowTabBarWhenNeeded
      '';

      # ntfy-sh client configuration for custom server
      xdg.configFile."ntfy/client.yml".text = ''
        default-host: ${inputs.private.services.ntfy}

        subscribe:
          - topic: newmedia
            command: '${config.home.homeDirectory}/.local/bin/ntfy-linkshare "$t" "$m"'
          - topic: changedetection
            command: '${config.home.homeDirectory}/.local/bin/ntfy-linkshare "$t" "$m"'
          - topic: linkshare
            command: '${config.home.homeDirectory}/.local/bin/ntfy-linkshare "$t" "$m"'
          - topic: plex
            command: '${config.home.homeDirectory}/.local/bin/ntfy-linkshare "$t" "$m"'
          - topic: arrs
            command: '${config.home.homeDirectory}/.local/bin/ntfy-linkshare "$t" "$m"'
      '';

      # ntfy-sh systemd service for desktop notifications
      systemd.user.services.ntfy-notifications = {
        Unit = {
          Description = "ntfy.sh notification subscriber";
          After = ["graphical-session.target" "agenix.service" "network-online.target"];
          Wants = ["network-online.target"];
        };

        Service = {
          Type = "simple";
          # Use a wrapper script to read token, fetch missed messages, then start subscription
          ExecStart = pkgs.writeShellScript "ntfy-with-token" ''
            TOKEN=$(cat ${config.age.secrets.ntfy-token.path})

            # On startup, fetch any messages from the last hour that we might have missed
            # while the computer was asleep or service was down
            ${pkgs.ntfy-sh}/bin/ntfy sub --from-config --token "$TOKEN" --poll --since 1h 2>/dev/null || true

            # Now start the persistent subscription
            exec ${pkgs.ntfy-sh}/bin/ntfy sub --from-config --token "$TOKEN"
          '';
          Restart = "always";
          RestartSec = "10s";
          # Restart on network failures
          RestartForceExitStatus = [1];
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };

      # caffeine-ng systemd service to prevent screen sleep/lock
      systemd.user.services.caffeine = {
        Unit = {
          Description = "Caffeine - prevent screen sleep and lock";
          After = ["graphical-session.target"];
        };

        Service = {
          Type = "simple";
          ExecStart = "${pkgs.caffeine-ng}/bin/caffeine";
          Restart = "on-failure";
          RestartSec = "5s";
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  }
