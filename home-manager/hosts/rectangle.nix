# Home-manager configuration for rectangle
# Raspberry Pi 5 streaming client with minimal i3 setup
{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../common/base.nix
    ../common/packages.nix
  ];

  # Packages inherited from common/packages.nix
  # Additional host-specific packages can be added via home.packages if needed

  # Explicitly enable mynix modules for this host
  mynix = {
    # i3 window manager (not Hyprland)
    i3.enable = true;

    # Shell and terminal
    zsh.enable = true;
    starship.enable = true;
    nushell.enable = true;

    # Terminal utilities (minimal set)
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

      # Explicitly disable broken packages on aarch64
      gren.enable = lib.mkForce false;
      poetry.enable = false;
      opencode.enable = false;
    };

    # Development (limited)
    devbox = {
      enable = true;
      enhancedShell = true;
      direnv = true;
    };

    # Disable Elm (broken on aarch64)
    elm.enable = lib.mkForce false;

    # Other tools
    ssh.enable = true;
    notes.zk.enable = true;
    television.enable = true;
  };

  # Disable formatters and AI plugins in nvim for aarch64
  programs.nvf.settings.vim = {
    languages = {
      markdown.format.enable = lib.mkForce false;
      css.format.enable = lib.mkForce false;
      ts.format.enable = lib.mkForce false;
    };

    assistant.codecompanion-nvim.enable = lib.mkForce false;

    # Disable Gren treesitter grammar (has broken Haskell dependencies on aarch64)
    treesitter.grammars = lib.mkForce [
      pkgs.tree-sitter-grammars.tree-sitter-norg
      pkgs.tree-sitter-grammars.tree-sitter-norg-meta
    ];
  };
}
