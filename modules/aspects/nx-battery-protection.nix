{ ... }:
{
  flake.aspects.nx-battery-protection = {
    nixos = { ... }: {
      mynix.battery-protection.enable = true;
    };
  };
}
