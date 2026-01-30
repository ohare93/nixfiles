{ ... }:
{
  flake.aspects.hm-immich = {
    homeManager = { ... }: {
      mynix.immich = {
        enable = true;
        autoUploader.enable = true;
        cli.enable = true;
      };
    };
  };
}
