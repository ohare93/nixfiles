# Home-manager configuration for hatch
# Secondary GUI workstation with Immich tools
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

    # Shell and terminal
    zsh.enable = true;
    starship.enable = true;
    nushell.enable = true;
    kitty.enable = true;

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

    # Immich tools (specific to hatch)
    immich = {
      enable = true;
      autoUploader.enable = true;
      cli.enable = true;
    };

    # Other tools
    ssh.enable = true;
    notes.zk.enable = true;
    television.enable = true;
    yazi.enable = true;
    espanso.enable = true;
  };
}
