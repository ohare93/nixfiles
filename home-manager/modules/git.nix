{inputs, ...}: {
  programs.git = {
    enable = true;

    # Global gitignore patterns
    ignores = [
      ".claude/settings.local.json"
    ];

    # URL rewriting to abstract private flake location
    extraConfig = {
      url."ssh://private-git/jmo/nixfiles.private" = {
        insteadOf = "ssh://private-config";
      };
    };
  };
}
