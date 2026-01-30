{ ... }:
{
  flake.aspects.hm-devbox = {
    homeManager = { ... }: {
      mynix.devbox = {
        enable = true;
        enhancedShell = true;
        direnv = true;
      };
    };
  };
}
