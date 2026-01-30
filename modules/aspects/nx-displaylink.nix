{ ... }:
{
  flake.aspects.nx-displaylink = {
    nixos = { ... }: {
      mynix.displaylink.enable = true;
    };
  };
}
