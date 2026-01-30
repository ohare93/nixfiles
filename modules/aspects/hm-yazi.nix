{ ... }:
{
  flake.aspects.hm-yazi = {
    homeManager = { ... }: {
      mynix.yazi.enable = true;
    };
  };
}
