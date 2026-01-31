{ self, ... }:
{
  flake.aspects.hm-desktop-dev = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-devbox
        self.modules.homeManager.hm-terminal-dev
      ];
    };
  };
}
