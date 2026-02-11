{ ... }:
{
  flake.aspects.nx-niri-system = {
    nixos = { ... }: {
      mynix.niri-system.enable = true;
    };
  };
}
