{ self, ... }:
{
  flake.aspects.hm-cli-base = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-shells
        self.modules.homeManager.hm-shells-nushell
        self.modules.homeManager.hm-terminal-base
        self.modules.homeManager.hm-ssh
        self.modules.homeManager.hm-notes
        self.modules.homeManager.hm-television
        self.modules.homeManager.hm-yazi
      ];
    };
  };
}
