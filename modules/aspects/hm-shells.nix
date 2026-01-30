{ ... }:
{
  flake.aspects.hm-shells = {
    homeManager = { ... }: {
      mynix = {
        zsh.enable = true;
        starship.enable = true;
        nushell.enable = true;
      };
    };
  };
}
