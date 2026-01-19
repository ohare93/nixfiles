{
  inputs,
  pkgs,
  hostname,
  ...
}: {
  imports = [
    ./modules
  ];

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # Binary cache for Claude Code
  nix.settings = {
    substituters = ["https://claude-code.cachix.org"];
    trusted-public-keys = ["claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="];
  };

  # Configure nh with flake location
  programs.nh = {
    enable = true;
    flake = "/home/jmo/nixfiles";
  };

  environment.systemPackages = with pkgs; [
    # Basic utilities
    wget
    curl
    git
    htop
    tree
    tldr

    # Archive/compression tools
    unzip
    zip
    p7zip
    gnutar
    gzip
    bzip2
    xz

    # File operations
    rsync
    file
    which

    # Network tools
    netcat

    # Development
    nodejs

    # System management
    home-manager
    inputs.agenix.packages.${pkgs.system}.default
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.hasklug
  ];

  programs.neovim.enable = true;

  programs.zsh.enable = true;

  users.users.jmo = {
    isNormalUser = true;
    description = inputs.private.identity.fullName;
    extraGroups = ["networkmanager" "wheel" "uinput"];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };
}
