{
  lib,
  config,
  ...
}: let
  cfg = config.mynix.battery-protection;
in
  with lib; {
    options.mynix = {
      battery-protection = {
        enable = mkEnableOption "Battery protection with UPower and TLP";

        upower = {
          percentageLow = mkOption {
            type = types.int;
            default = 50;
            description = "Battery percentage considered low";
          };

          percentageCritical = mkOption {
            type = types.int;
            default = 40;
            description = "Battery percentage considered critical";
          };

          percentageAction = mkOption {
            type = types.int;
            default = 35;
            description = "Battery percentage at which to take action";
          };

          criticalPowerAction = mkOption {
            type = types.str;
            default = "Suspend";
            description = "Action to take at critical battery level (PowerOff, Hibernate, HybridSleep, Suspend, Ignore)";
          };
        };

        tlp = {
          startChargeThreshold = mkOption {
            type = types.int;
            default = 0;
            description = "Battery percentage at which to start charging (0 = charge from any level)";
          };

          stopChargeThreshold = mkOption {
            type = types.int;
            default = 80;
            description = "Battery percentage at which to stop charging";
          };
        };
      };
    };

    config = mkIf cfg.enable {
      # Battery protection - prevents unexpected shutdown on miscalibrated batteries
      services.upower = {
        enable = true;
        inherit (cfg.upower) percentageLow;
        inherit (cfg.upower) percentageCritical;
        inherit (cfg.upower) percentageAction;
        inherit (cfg.upower) criticalPowerAction;
        allowRiskyCriticalPowerAction = true; # Required for Suspend action
      };

      # TLP for better battery management and health
      services.tlp = {
        enable = true;
        settings = {
          START_CHARGE_THRESH_BAT0 = cfg.tlp.startChargeThreshold;
          STOP_CHARGE_THRESH_BAT0 = cfg.tlp.stopChargeThreshold;
        };
      };
    };
  }
