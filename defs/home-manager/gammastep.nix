{
  lib,
  config,
  ...
}: let
  cfg = config.mynix.gammastep;
in
  with lib; {
    options.mynix = {
      gammastep = {
        enable = mkEnableOption "gammastep screen color temperature";
      };
    };

    config = mkIf cfg.enable {
      services.gammastep = {
        enable = true;
        provider = "manual";
        latitude = 55.68;
        longitude = 12.57;
        temperature = {
          day = 5500;
          night = 1200;
        };
        tray = true;
      };
    };
  }
