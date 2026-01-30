{ ... }:
{
  flake.aspects.nx-agentic-coding = {
    nixos = { ... }: {
      mynix.agentic-coding.enable = true;
    };
  };
}
