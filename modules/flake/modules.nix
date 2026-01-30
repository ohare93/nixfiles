_: {
  # Export custom NixOS modules
  flake.nixosModules = import ../../defs/nixos;

  # Export custom Home Manager modules
  flake.homeManagerModules = import ../../defs/home-manager;
}
