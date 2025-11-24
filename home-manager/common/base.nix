# Base home-manager configuration shared across all hosts
# This file contains fundamental settings that every host needs
# It does NOT enable mynix modules - those are enabled per-host
{
  inputs,
  ...
}: {
  # Import mynix module definitions
  imports = [
    ../modules
  ];

  # Disable the default git-credential-keepassxc module
  disabledModules = ["programs/git-credential-keepassxc.nix"];

  # Basic home-manager settings
  home = {
    username = "jmo";
    homeDirectory = inputs.private.paths.home;
    stateVersion = "25.05";

    # Default environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less -FRX";
    };
  };

  # Enable home-manager self-management
  programs.home-manager.enable = true;
}
