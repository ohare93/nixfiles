{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../common/base.nix
  ];

  home.packages = with pkgs; [
    htop
    btop
    tree
    jq
    dnsutils
    lsof
    procps
    psmisc
    usbutils
    pciutils
    gum
    ripgrep
    fd
    bat
    iotop
    ncdu
    xclip
    wl-clipboard
    inputs.nixpkgs.legacyPackages.${pkgs.system}.jujutsu
  ];

  programs.jujutsu.enable = lib.mkForce false;

  mynix = {
    i3.enable = true;
    kitty.enable = true;
    zsh.enable = true;
    starship.enable = false;
    nushell.enable = false;

    terminal-misc = {
      zoxide.enable = true;
      atuin.enable = true;
      claude.enable = true;
      zellij.enable = false;
      fzf.enable = false;
      carapace.enable = false;
      devbox.enable = false;
      comma.enable = false;
      nvd.enable = false;
      gren.enable = lib.mkForce false;
      poetry.enable = false;
      opencode.enable = false;
    };

    devbox.enable = false;
    notes.zk.enable = false;
    television.enable = false;
    yazi.enable = false;
    elm.enable = lib.mkForce false;
    ssh.enable = true;
    qutebrowser.enable = false;
  };

  programs.nvf.enable = lib.mkForce false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set smartindent
      set ignorecase
      set smartcase
      set clipboard=unnamedplus
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
