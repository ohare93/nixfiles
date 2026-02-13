{
  lib,
  config,
  ...
}: let
  cfg = config.mynix.wlsunset;
in
  with lib; {
    options.mynix = {
      wlsunset = {
        enable = mkEnableOption "wlsunset blue light filter (for Niri/wlroots compositors)";
      };
    };

    config = mkIf cfg.enable {
      services.wlsunset = {
        enable = true;
        latitude = "56.15"; # Aarhus
        longitude = "10.21";
        temperature = {
          day = 6500;
          night = 4000;
        };
      };
    };
  }
