{ ... }:
{
  flake.aspects.hm-terminal-dev = {
    homeManager = { ... }: {
      mynix.terminal-misc = {
        devbox.enable = true;
        poetry.enable = true;
        comma.enable = true;
        gren.enable = true;
        nvd.enable = true;
      };
    };
  };
}
