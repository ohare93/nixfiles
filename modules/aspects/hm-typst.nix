{ ... }:
{
  flake.aspects.hm-typst = {
    homeManager = { ... }: {
      mynix.typst.enable = true;
    };
  };
}
