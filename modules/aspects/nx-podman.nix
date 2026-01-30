{ ... }:
{
  flake.aspects.nx-podman = {
    nixos = { ... }: {
      mynix.podman.enable = true;
    };
  };
}
