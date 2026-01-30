{ ... }:
{
  flake.aspects.hm-kitty = {
    homeManager = { ... }: {
      mynix.kitty.enable = true;
    };
  };
}
