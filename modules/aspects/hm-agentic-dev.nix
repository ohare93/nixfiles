{ ... }:
{
  flake.aspects.hm-agentic-dev = {
    homeManager = { ... }: {
      mynix.agentic-dev.enable = true;
    };
  };
}
