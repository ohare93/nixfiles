{ self, ... }:
{
  flake.aspects."loophole.host" = {
    nixos = { ... }: {
      # WSL host has no extra system-specific settings beyond mkWSL defaults.
    };
  };

  flake.aspects."loophole.home" = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-cli-base
        self.modules.homeManager.hm-devbox
        self.modules.homeManager.hm-terminal-dev
        self.modules.homeManager.hm-desktop-ai-lite
      ];

      # Disable GUI-only features for WSL
      mynix = {
        gui-software.enable = false;
        hyprland.enable = false;
        syncthing.enable = false;
      };
    };
  };
}
