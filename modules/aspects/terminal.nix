{...}: {
  flake.aspects.terminal = {
    homeManager = {
      mynix = {
        zsh.enable = true;
        starship.enable = true;
        nushell.enable = true;
        terminal-misc = {
          zoxide.enable = true;
          zellij.enable = true;
          atuin.enable = true;
          fzf.enable = true;
          carapace.enable = true;
        };
      };
    };
  };
}
