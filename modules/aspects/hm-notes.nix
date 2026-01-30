{ ... }:
{
  flake.aspects.hm-notes = {
    homeManager = { ... }: {
      mynix.notes.zk.enable = true;
    };
  };
}
