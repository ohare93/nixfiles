{
  inputs,
  lib,
  config,
  ...
}: {
  system.stateVersion = "25.05";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      download-buffer-size = 268435456; # 256 MB
    };

    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Use the same nixpkgs as the system
    registry = lib.mkForce (lib.mapAttrs (_: value: {flake = value;}) inputs);
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };
}
