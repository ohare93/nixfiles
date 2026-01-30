{ inputs, ... }:
{
  flake.aspects.definitions = {
    nixos = { ... }: {
      imports = [
        (inputs.self + "/defs/nixos")
      ];
    };

    homeManager = { ... }: {
      imports = [
        (inputs.self + "/defs/home-manager")
      ];
    };
  };
}
