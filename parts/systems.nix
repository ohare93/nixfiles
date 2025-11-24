{inputs, ...}: {
  # Define which systems this flake supports
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # Per-system configuration
  perSystem = {
    system,
    ...
  }: {
    # Override pkgs with our custom configuration
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfreePredicate = inputs.self.lib.allowUnfreePredicate;
      config.allowBrokenPredicate = inputs.self.lib.allowBrokenPredicate;
      overlays = builtins.attrValues inputs.self.overlays;
    };
  };
}
