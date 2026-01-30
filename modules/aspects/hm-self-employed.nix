{ ... }:
{
  flake.aspects.hm-self-employed = {
    homeManager = { ... }: {
      mynix.self-employed.enable = true;
    };
  };
}
