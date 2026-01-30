{
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.mynix.syncthing;
in
  with lib; {
    options.mynix = {
      syncthing = {
        enable = mkEnableOption "Syncthing";
      };
    };

    config = mkIf cfg.enable {
      services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        overrideDevices = true;
        overrideFolders = true;
        settings = {
          inherit (inputs.private.syncthing) devices;
          folders = {
            "${inputs.private.syncthing.folders.fileShare.id}" = {
              inherit (inputs.private.syncthing.folders.fileShare) label;
              path = "${inputs.private.paths.sync}/${inputs.private.syncthing.folders.fileShare.label}";
              devices = ["thebox" "overton" "hatch"];
            };
            "${inputs.private.syncthing.folders.oneTime.id}" = {
              inherit (inputs.private.syncthing.folders.oneTime) label;
              path = "${inputs.private.paths.sync}/${inputs.private.syncthing.folders.oneTime.label}";
              devices = ["thebox" "overton" "hatch"];
            };
            "${inputs.private.syncthing.folders.dockerUnraid.id}" = {
              inherit (inputs.private.syncthing.folders.dockerUnraid) label;
              path = "${inputs.private.paths.development}/${inputs.private.syncthing.folders.dockerUnraid.label}";
              devices = ["thebox" "overton" "hatch"];
            };
            "${inputs.private.syncthing.folders.obsidian.id}" = {
              inherit (inputs.private.syncthing.folders.obsidian) label;
              path = "${inputs.private.paths.sync}/${inputs.private.syncthing.folders.obsidian.label}";
              devices = ["thebox" "overton"];
            };
          };
        };
      };
    };
  }
