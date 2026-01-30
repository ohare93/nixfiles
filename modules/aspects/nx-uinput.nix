{ ... }:
{
  flake.aspects.nx-uinput = {
    nixos = { ... }: {
      mynix.uinput.enable = true;
    };
  };
}
