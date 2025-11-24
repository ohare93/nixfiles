{
  lib,
  config,
  ...
}: let
  cfg = config.mynix.plasma;
in
  with lib; {
    options.mynix = {
      plasma = {
        enable = mkEnableOption "KDE Plasma Desktop Configuration";
      };
    };

    config = mkIf cfg.enable {
      programs.plasma = {
        enable = true;

        panels = [
          # Bottom panel with taskbar
          {
            location = "bottom";
            widgets = [
              # Application launcher
              {
                name = "org.kde.plasma.kickoff";
                config = {
                  General = {
                    icon = "start-here-kde";
                  };
                };
              }

              # Icon-only task manager with pinned applications
              {
                name = "org.kde.plasma.icontasks";
                config = {
                  General = {
                    launchers = [
                      "applications:org.qutebrowser.qutebrowser.desktop"
                      "applications:org.kde.konsole.desktop"
                      "applications:org.telegram.desktop.desktop"
                      "applications:plexamp.desktop"
                      "applications:signal-desktop.desktop"
                    ];
                  };
                };
              }

              # Spacer
              "org.kde.plasma.panelspacer"

              # System tray
              {
                name = "org.kde.plasma.systemtray";
                config = {
                  General = {
                    extraItems = [
                      "org.kde.plasma.clipboard"
                      "org.kde.plasma.devicenotifier"
                      "org.kde.plasma.manage-inputmethod"
                      "org.kde.plasma.notifications"
                      "org.kde.plasma.keyboardindicator"
                      "org.kde.plasma.networkmanagement"
                      "org.kde.plasma.volume"
                      "org.kde.plasma.bluetooth"
                      "org.kde.plasma.battery"
                    ];
                  };
                };
              }

              # Digital clock
              {
                name = "org.kde.plasma.digitalclock";
                config = {
                  Appearance = {
                    dateDisplayFormat = "BelowTime";
                    showSeconds = "Always";
                  };
                };
              }
            ];
          }
        ];
      };
    };
  }
