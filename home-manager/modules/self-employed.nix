{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.self-employed;
in
  with lib; {
    options.mynix = {
      self-employed = {
        enable = mkEnableOption "Self-employment tools (Slack, Notion)";
      };
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        slack
        notion-app-enhanced
      ];
    };
  }
