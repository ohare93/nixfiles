{ ... }:
{
  flake.aspects.hm-shells-nushell = {
    homeManager = { ... }: {
      mynix.nushell.enable = true;
    };
  };
}
