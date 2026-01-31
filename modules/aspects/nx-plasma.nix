{ ... }:
{
  flake.aspects.nx-plasma = {
    nixos = { ... }: {
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;
    };
  };
}
