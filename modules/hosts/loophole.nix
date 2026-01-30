{ ... }:
{
  flake.aspects.host-loophole = {
    nixos = { ... }: {
      # WSL host has no extra system-specific settings beyond mkWSL defaults.
    };
  };
}
