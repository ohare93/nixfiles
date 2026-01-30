{ ... }:
{
  flake.aspects.hm-espanso = {
    homeManager = { ... }: {
      mynix.espanso.enable = true;
    };
  };
}
