# Home-manager configuration for aperture
# Microsoft Surface Go 2 tablet with KDE Plasma
{ ...}: {
  imports = [
    ../common/base.nix
    ../common/packages.nix
  ];

  # Explicitly enable mynix modules for this host
  mynix = {
    # GUI applications (uses Plasma instead of Hyprland)
    gui-software.enable = true;
    plasma.enable = true; # KDE Plasma instead of Hyprland
    syncthing.enable = true;
    waybar-updates.enable = false; # Not needed for Plasma

    # Shell and terminal
    zsh.enable = true;
    starship.enable = true;
    nushell.enable = true;

    # Development tools
    devbox = {
      enable = true;
      enhancedShell = true;
      direnv = true;
    };

    # Terminal utilities
    terminal-misc = {
      zoxide.enable = true;
      zellij.enable = true;
      atuin.enable = true;
      fzf.enable = true;
      carapace.enable = true;
      claude.enable = true;
      devbox.enable = true;
      poetry.enable = true;
      comma.enable = true;
      gren.enable = true;
      nvd.enable = true;
      opencode.enable = true;
    };

    # Other tools
    ssh.enable = true;
    notes.zk.enable = true;
    television.enable = true;
  };
}
