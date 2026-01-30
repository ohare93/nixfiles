{
  lib,
  config,
  ...
}: let
  cfg = config.mynix.nix-signing;

  # Public keys for signature verification (all machines trust these)
  trustedSigningKeys = [
    "skylight-1:xG5/rtGL/okVc29XLaVfLxi1KjVAURkUIvG41o0w2gg="
    "overton-1:N3D3Zp2xdNt2zojjZwJK6MPoDieLaxIA5zu5/hwzH/I="
  ];
in
  with lib; {
    options.mynix.nix-signing = {
      enableSigning = mkEnableOption "Enable path signing on this machine";

      signingKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the secret signing key file (typically an agenix-decrypted path)";
      };
    };

    config = {
      # All machines trust our signing keys
      nix.settings.trusted-public-keys = trustedSigningKeys;

      # Signing machines get secret-key-files configured
      nix.settings.secret-key-files = mkIf (cfg.enableSigning && cfg.signingKeyFile != null) [
        cfg.signingKeyFile
      ];
    };
  }
