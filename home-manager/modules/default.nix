{
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Import custom packages
  customPackages = import ../packages {inherit pkgs lib;};
in {
  imports = [
    ./syncthing.nix
    ./jujutsu.nix
    ./git.nix
    ./gui-software.nix
    ./qutebrowser.nix
    ./hyprland.nix
    ./i3.nix
    ./zsh.nix
    ./terminal.nix
    ./ssh.nix
    ./nvf
    ./notes.nix
    ./elm.nix
    ./devbox.nix
    ./immich.nix
    ./television.nix
    ./yazi.nix
    ./kitty.nix
    ./nushell.nix
    ./starship.nix
    ./neomutt.nix
    ./stmp.nix
    ./bitwarden.nix
    inputs.immich-auto-uploader.nixosModules.home-manager
  ];

  # Add custom packages
  config.home.packages = [
    customPackages.beads
  ];
}
