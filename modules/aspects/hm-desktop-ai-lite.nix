{ self, ... }:
{
  flake.aspects.hm-desktop-ai-lite = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-terminal-ai-lite
      ];
    };
  };
}
