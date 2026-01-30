{ ... }:
{
  flake.aspects.hm-syncthing = {
    homeManager = { ... }: {
      mynix.syncthing.enable = true;
    };
  };
}
