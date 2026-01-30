{ self, ... }:
{
  flake.aspects.home-overton = {
    homeManager = { lib, ... }: {
      imports = [
        self.modules.homeManager.terminal
        self.modules.homeManager.wm
        self.modules.homeManager.hm-shells
        self.modules.homeManager.hm-shells-nushell
        self.modules.homeManager.hm-kitty
        self.modules.homeManager.hm-devbox
        self.modules.homeManager.hm-terminal-dev
        self.modules.homeManager.hm-terminal-ai-full
        self.modules.homeManager.hm-syncthing
        self.modules.homeManager.hm-ssh
        self.modules.homeManager.hm-notes
        self.modules.homeManager.hm-television
        self.modules.homeManager.hm-yazi
        self.modules.homeManager.hm-stmp
        self.modules.homeManager.hm-bitwarden
        self.modules.homeManager.hm-typst
        self.modules.homeManager.hm-espanso
        self.modules.homeManager.hm-self-employed
      ];

      programs.zellij.enableZshIntegration = lib.mkForce false;
    };
  };
}
