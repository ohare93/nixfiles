{ ... }:
{
  flake.aspects.hm-plasma = {
    homeManager = { ... }: {
      mynix = {
        gui-software.enable = true;
        plasma.enable = true;
      };
    };
  };
}
