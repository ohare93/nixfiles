_: {
  # Shared library functions and constants
  flake.lib = {
    # Unfree packages to allow
    unfreePackages = [
      "displaylink"
      "plexamp"
      "keymapp"
      "claude-code"
    ];

    # Broken packages to allow
    brokenPackages = [
      "prettyprint-avh4"
    ];

    # Predicate function for unfree packages
    allowUnfreePredicate = pkg:
      builtins.elem
      (pkg.pname or (builtins.parseDrvName pkg.name).name)
      [
        "displaylink"
        "plexamp"
        "keymapp"
        "claude-code"
      ];

    # Predicate function for broken packages
    allowBrokenPredicate = pkg:
      builtins.elem
      (pkg.pname or (builtins.parseDrvName pkg.name).name)
      [
        "prettyprint-avh4"
      ];
  };
}
