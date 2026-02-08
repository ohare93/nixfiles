{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.ssh.ca;
  trustedUserCaPath =
    if cfg.publicKey != null
    then "/etc/ssh/ssh_user_ca.pub"
    else cfg.publicKeyFile;
in {
  options.mynix.ssh.ca = {
    enable = lib.mkEnableOption "SSH user CA trust";
    publicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SSH user CA public key text (writes /etc/ssh/ssh_user_ca.pub).";
    };
    publicKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to SSH user CA public key file.";
    };
    authorizedPrincipalsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional AuthorizedPrincipalsFile path for SSH user CA principals.";
    };
  };

  config = lib.mkMerge [
    {
      # WireGuard VPN support
      networking.wireguard.enable = true;

      # Enable WireGuard tools in system packages
      environment.systemPackages = with pkgs; [
        wireguard-tools
      ];

      # Open firewall port for WireGuard (if needed)
      # networking.firewall.allowedUDPPorts = [ 51820 ];
    }
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.publicKey != null || cfg.publicKeyFile != null;
          message = "mynix.ssh.ca.enable requires either mynix.ssh.ca.publicKey or mynix.ssh.ca.publicKeyFile.";
        }
      ];

      environment.etc = lib.mkIf (cfg.publicKey != null) {
        "ssh/ssh_user_ca.pub" = {
          text = cfg.publicKey;
          mode = "0644";
        };
      };

      services.openssh.settings =
        {
          TrustedUserCAKeys = trustedUserCaPath;
        }
        // lib.optionalAttrs (cfg.authorizedPrincipalsFile != null) {
          AuthorizedPrincipalsFile = cfg.authorizedPrincipalsFile;
        };
    })
  ];
}
