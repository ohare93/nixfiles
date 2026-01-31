{ self, ... }:
{
  flake.aspects.hm-desktop-ai-full = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-terminal-ai-full
      ];
    };
  };
}
