# Home-manager configuration for overton
# Primary GUI workstation with development tools
{ ...}: {
  imports = [
    ../common/base.nix
    ../common/packages.nix
  ];

  # Explicitly enable mynix modules for this host
  mynix = {
    # GUI applications
    gui-software.enable = true;
    hyprland.enable = true;
    syncthing.enable = true;
    waybar-updates.enable = true;

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
    yazi.enable = true;
    stmp.enable = true;
    bitwarden.enable = true;
  };
}
