{
  lib,
  config,
  ...
}: let
  cfg = config.mynix.hyprsunset;
in
  with lib; {
    options.mynix = {
      hyprsunset = {
        enable = mkEnableOption "hyprsunset blue light filter";
      };
    };

    config = mkIf cfg.enable {
      services.hyprsunset = {
        enable = true;
        settings = {
          max-gamma = 150;

          profile = [
            # Daytime: no filter
            {
              time = "07:00";
              identity = true;
            }
            # Sunset: darkroom mode - deep red + dim
            {
              time = "18:00";
              temperature = 1200;
              gamma = 40;
            }
          ];
        };
      };
    };
  }
