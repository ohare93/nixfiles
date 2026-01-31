{ self, ... }:
{
  flake.aspects.hm-desktop-plasma = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-plasma
      ];
    };
  };
}
