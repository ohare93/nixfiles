{ ... }:
{
  flake.aspects.hm-ssh = {
    homeManager = { ... }: {
      mynix.ssh.enable = true;
    };
  };
}
