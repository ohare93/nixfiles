{ ... }:
{
  flake.aspects.hm-television = {
    homeManager = { ... }: {
      mynix.television.enable = true;
    };
  };
}
