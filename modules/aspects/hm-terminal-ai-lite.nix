{ ... }:
{
  flake.aspects.hm-terminal-ai-lite = {
    homeManager = { ... }: {
      mynix.terminal-misc = {
        claude.enable = true;
        opencode.enable = true;
      };
    };
  };
}
