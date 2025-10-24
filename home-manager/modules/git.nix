{...}: {
  programs.git = {
    enable = true;

    # Global gitignore patterns
    ignores = [
      ".claude/settings.local.json"
    ];
  };
}
