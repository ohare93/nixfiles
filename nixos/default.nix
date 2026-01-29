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
    extraGroups = ["networkmanager" "wheel" "uinput" "input"];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };
}
