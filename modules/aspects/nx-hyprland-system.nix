{ ... }:
{
  flake.aspects.nx-hyprland-system = {
    nixos = { ... }: {
      mynix.hyprland-system.enable = true;
    };
  };
}
