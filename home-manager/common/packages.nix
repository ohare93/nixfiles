# Shared packages installed across most/all hosts
# These are packages that don't have mynix module wrappers
# Host-specific packages should be added in the host configuration
{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    # System utilities
    htop
    bottom # Modern system monitor
    btop # Another modern system monitor
    remmina # VNC/RDP remote desktop client
    tree
    ripgrep
    fd
    bat
    bat-extras.batman # Man pages with bat
    eza
    yazi # Terminal file manager
    jq
    dnsutils
    nixd
    lsof
    procps
    psmisc
    usbutils
    pciutils
    asciinema
    croc
    ttyd
    newsboat
    grex
    gum # CLI UI toolkit
    gh # GitHub CLI
    pass # Password manager
    doppler # Secrets management CLI

    # Text processing
    diffutils
    patch
    gnused
    gnugrep

    # Development tools
    gcc
    gnumake
    cmake
    pkg-config
    just # Command runner
    xclip
    wl-clipboard
    openssl
    (python3.withPackages (ps: [ps.faker]))

    # Performance monitoring
    iotop
    ncdu
    dust # Modern disk usage analyzer
    dua # Interactive disk usage
    strace

    # Container tools
    skopeo

    # Media and graphics
    feh
    mpv
    alsa-utils
    sox
    ffmpeg
    poppler-utils
    imagemagick
    ghostscript

    # Fun CLI tools
    cbonsai
    lolcat

    # Privacy tools
    inputs.privacy-filter.packages.${pkgs.system}.default
  ];
}
