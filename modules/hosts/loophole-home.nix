{ self, ... }:
{
  flake.aspects.home-loophole = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.terminal
        self.modules.homeManager.hm-shells
        self.modules.homeManager.hm-shells-nushell
        self.modules.homeManager.hm-devbox
        self.modules.homeManager.hm-terminal-dev
        self.modules.homeManager.hm-terminal-ai-lite
        self.modules.homeManager.hm-ssh
        self.modules.homeManager.hm-notes
        self.modules.homeManager.hm-television
        self.modules.homeManager.hm-yazi
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
