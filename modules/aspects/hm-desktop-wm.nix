{ self, ... }:
{
  flake.aspects.hm-desktop-wm = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.wm
        self.modules.homeManager.hm-kitty
      ];
    };
  };
}
