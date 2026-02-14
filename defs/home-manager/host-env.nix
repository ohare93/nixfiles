{
  lib,
  config,
  hostname,
  ...
}: let
  cfg = config.mynix.host-env;
in
  with lib; {
    options.mynix = {
      host-env = {
        enable = mkEnableOption "host-specific environment variables from agenix secret";
      };
    };

    config = mkIf cfg.enable {
      age.secrets."${hostname}-env" = {
        file = ../../secrets/${hostname}-env.age;
      };

      programs.zsh.initContent = lib.mkOrder 100 ''
        if [[ -f "${config.age.secrets."${hostname}-env".path}" ]]; then
          set -a
          source "${config.age.secrets."${hostname}-env".path}"
          set +a
        fi
      '';
    };
  }
