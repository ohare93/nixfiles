{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.mynix.immich;
in
  with lib; {
    options.mynix.immich = {
      enable = mkEnableOption "Immich tools and services";

      autoUploader = {
        enable = mkEnableOption "Immich auto-uploader service";

        environmentFile = mkOption {
          type = types.str;
          default = "${inputs.private.paths.home}/.config/immich-auto-uploader/.env";
          description = "Path to environment file containing sensitive configuration";
        };

        apiUrl = mkOption {
          type = types.str;
          default = inputs.private.services.immich;
          description = "Immich API URL";
        };

        watchDirectories = mkOption {
          type = types.str;
          default = "${inputs.private.paths.home}/Downloads,'${inputs.private.paths.home}/Downloads/Telegram Desktop'";
          description = "Comma-separated list of directories to watch";
        };

        watchRecursive = mkOption {
          type = types.str;
          default = "false";
          description = "Whether to watch directories recursively";
        };

        archiveDirectory = mkOption {
          type = types.str;
          default = "${inputs.private.paths.home}/Downloads/UploadArchive";
          description = "Directory to move uploaded files to";
        };

        supportedExtensions = mkOption {
          type = types.str;
          default = "jpg,jpeg,png,gif,mp4,mov";
          description = "Comma-separated list of supported file extensions";
        };

        pollIntervalSeconds = mkOption {
          type = types.str;
          default = "30";
          description = "Polling interval in seconds";
        };

        logLevel = mkOption {
          type = types.str;
          default = "Info";
          description = "Log level (Debug, Info, Warn, Error)";
        };

        maxFileSizeMb = mkOption {
          type = types.str;
          default = "1000";
          description = "Maximum file size in MB";
        };
      };

      cli = {
        enable = mkEnableOption "Immich command-line interface";

        package = mkOption {
          type = types.package;
          default = pkgs.immich-cli;
          description = "Immich CLI package to use";
        };
      };
    };

    config = mkIf cfg.enable {
      # Auto-uploader service
      services.immich-auto-uploader = mkIf cfg.autoUploader.enable {
        enable = true;
        inherit (cfg.autoUploader) environmentFile;
        settings = {
          IMMICH_API_URL = cfg.autoUploader.apiUrl;
          WATCH_DIRECTORIES = cfg.autoUploader.watchDirectories;
          WATCH_RECURSIVE = cfg.autoUploader.watchRecursive;
          ARCHIVE_DIRECTORY = cfg.autoUploader.archiveDirectory;
          SUPPORTED_EXTENSIONS = cfg.autoUploader.supportedExtensions;
          POLL_INTERVAL_SECONDS = cfg.autoUploader.pollIntervalSeconds;
          LOG_LEVEL = cfg.autoUploader.logLevel;
          MAX_FILE_SIZE_MB = cfg.autoUploader.maxFileSizeMb;
        };
      };

      # Immich packages
      home.packages = lib.mkMerge [
        (mkIf cfg.cli.enable [cfg.cli.package])
      ];
    };
  }
