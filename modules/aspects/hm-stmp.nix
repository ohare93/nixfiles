{ ... }:
{
  flake.aspects.hm-stmp = {
    homeManager = { ... }: {
      mynix.stmp.enable = true;
    };
  };
}
