{ ... }:
{
  flake.aspects.hm-terminal-base = {
    homeManager = { ... }: {
      mynix.terminal-misc = {
        zoxide.enable = true;
        zellij.enable = true;
        atuin.enable = true;
        fzf.enable = true;
        carapace.enable = true;
      };
    };
  };
}
