_: {
  # Export custom NixOS modules
  flake.nixosModules = import ../nixos/modules;

  # Export custom Home Manager modules
  flake.homeManagerModules = import ../home-manager/modules;
}
