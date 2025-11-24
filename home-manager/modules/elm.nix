{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.elm;
in
  with lib; {
    options.mynix = {
      elm = {
        enable = mkEnableOption "elm development environment";

        elm-format.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable elm-format code formatter";
        };

        elm-test.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable elm-test testing framework";
        };

        elm-review.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable elm-review linter";
        };

        elm-live.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable elm-live development server";
        };

        elm-json.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable elm-json package management utility";
        };
      };
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs;
        [
          elmPackages.elm
          elmPackages.elm-language-server
        ]
        ++ lib.optional cfg.elm-format.enable elmPackages.elm-format
        ++ lib.optional cfg.elm-test.enable elmPackages.elm-test
        ++ lib.optional cfg.elm-review.enable elmPackages.elm-review
        ++ lib.optional cfg.elm-live.enable elmPackages.elm-live
        ++ lib.optional cfg.elm-json.enable elmPackages.elm-json;
    };
  }
