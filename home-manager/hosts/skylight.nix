# Home-manager configuration for skylight
# Headless build/test VM with minimal configuration
{
  ...
}: {
  imports = [
    ../common/base.nix
    ../common/packages.nix
  ];

  # Packages inherited from common/packages.nix
  # Additional host-specific packages can be added via home.packages if needed

  # Minimal mynix configuration for headless VM
  mynix = {
    # Shell and terminal
    zsh.enable = true;
    starship.enable = true;
    nushell.enable = true;

    # Essential terminal utilities
    terminal-misc = {
      zoxide.enable = true;
      zellij.enable = true;
      atuin.enable = true;
      fzf.enable = true;
      carapace.enable = true;
      claude.enable = true;
      devbox.enable = true;
      comma.enable = true;
      nvd.enable = true;

      # Disable heavy/unnecessary tools
      gren.enable = false;
      poetry.enable = false;
      opencode.enable = false;
    };

    # Development tools
    devbox = {
      enable = true;
      enhancedShell = true;
      direnv = true;
    };

    # Other essential tools
    ssh.enable = true;
    television.enable = true;
    yazi.enable = true;

    # Disable GUI and unnecessary features
    gui-software.enable = false;
    hyprland.enable = false;
    syncthing.enable = false;
    notes.zk.enable = false;
  };
}
