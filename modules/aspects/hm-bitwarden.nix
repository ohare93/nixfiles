{ ... }:
{
  flake.aspects.hm-bitwarden = {
    homeManager = { ... }: {
      mynix.bitwarden.enable = true;
    };
  };
}
