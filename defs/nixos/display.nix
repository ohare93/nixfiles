{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.displaylink;
in
  with lib; {
    options.mynix = {
      displaylink = {
        enable = mkEnableOption "Displaylink drivers";
      };
    };

    config = mkIf cfg.enable {
      services.xserver.videoDrivers = ["displaylink" "modesetting"];

      environment.systemPackages = with pkgs; [
        displaylink
      ];
    };
  }
