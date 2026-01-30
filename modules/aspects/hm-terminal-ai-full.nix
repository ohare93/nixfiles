{ ... }:
{
  flake.aspects.hm-terminal-ai-full = {
    homeManager = { ... }: {
      mynix.terminal-misc = {
        claude.enable = true;
        codex.enable = true;
        gemini.enable = true;
        opencode.enable = true;
      };
    };
  };
}
