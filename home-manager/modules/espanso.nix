{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.mynix.espanso;
  private = inputs.private.espanso;
in
  with lib; {
    options.mynix = {
      espanso = {
        enable = mkEnableOption "espanso text expander";
      };
    };

    config = mkIf cfg.enable {
      # wtype is required for text injection on Wayland
      home.packages = [pkgs.wtype];

      # Deploy emoji package as a file (too large for inline Nix)
      xdg.configFile."espanso/match/packages/all-emojis/package.yml".source = ../config/espanso/all-emojis.yml;

      services.espanso = {
        enable = true;
        configs = {
          default = {
            keyboard_layout = {
              layout = "dk";
            };
          };
          firefox = {
            filter_class = "Firefox";
            inject_delay = 10;
            key_delay = 10;
          };
          signal = {
            filter_title = "Signal";
            backend = "clipboard";
          };
          konsole = {
            filter_class = "konsole";
            enable = false;
          };
          terminal = {
            filter_exec = "terminal";
            enable = false;
          };
        };
        matches = {
          base = {
            matches = [
              # Date/time expansions
              {
                trigger = ":date";
                replace = "{{mydate}}";
                vars = [
                  {
                    name = "mydate";
                    type = "date";
                    params.format = "%Y-%m-%d";
                  }
                ];
              }
              {
                trigger = ":yest";
                replace = "{{mytime}}";
                vars = [
                  {
                    name = "mytime";
                    type = "date";
                    params = {
                      format = "%Y-%m-%d";
                      offset = -86400;
                    };
                  }
                ];
              }
              {
                trigger = ":tom";
                replace = "{{mytime}}";
                vars = [
                  {
                    name = "mytime";
                    type = "date";
                    params = {
                      format = "%Y-%m-%d";
                      offset = 86400;
                    };
                  }
                ];
              }
              {
                trigger = ":zet";
                replace = "{{mytime}}";
                vars = [
                  {
                    name = "mytime";
                    type = "date";
                    params.format = "%Y%m%d%H%M";
                  }
                ];
              }

              # Clipboard
              {
                trigger = ":paste";
                replace = "{{clipboard}}";
                vars = [
                  {
                    name = "clipboard";
                    type = "clipboard";
                  }
                ];
              }

              # Emoji shortcuts
              {
                trigger = ":g:";
                replace = "🟩";
              }
              {
                trigger = ":y:";
                replace = "🟨";
              }
              {
                trigger = ":b:";
                replace = "🟦";
              }
              {
                trigger = ":r:";
                replace = "🟥";
              }
              {
                trigger = ":swsm:";
                replace = "😅";
              }

              # Personal info (from private config)
              {
                trigger = ":jmo";
                replace = private.identity.personalEmail;
              }
              {
                trigger = ":linkedin";
                replace = private.identity.linkedinUrl;
              }
              {
                trigger = ":github";
                replace = private.identity.githubUrl;
              }
            ];
          };
        };
      };
    };
  }
