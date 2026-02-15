{ ... }:
{
  flake.aspects.hm-karakeep = {
    homeManager = { ... }: {
      mynix.karakeep.enable = true;
    };
  };
}
