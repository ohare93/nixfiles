{inputs, ...}: {
  flake.aspects.base = {
    nixos = {
      pkgs,
      config,
      hostname,
      ...
    }: {
      # Agenix identity path for decrypting secrets
      age.identityPaths = ["/home/jmo/.ssh/age_${hostname}"];

      # User password stored as agenix secret for declarative recovery
      age.secrets.jmo-password-hash = {
        file = inputs.self + "/secrets/jmo-password-hash.age";
        mode = "400";
      };
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
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
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
        # Password hash stored in agenix secret - enables recovery via generation rollback
        hashedPasswordFile = config.age.secrets.jmo-password-hash.path;
        packages = with pkgs; [];
      };
    };

    homeManager = {
      pkgs,
      inputs,
      ...
    }: {
      # Disable the default git-credential-keepassxc module
      disabledModules = ["programs/git-credential-keepassxc.nix"];

      # Basic home-manager settings
      home = {
        username = "jmo";
        homeDirectory = inputs.private.paths.home;
        stateVersion = "25.05";
        sessionPath = ["$HOME/.local/bin"];

        # Default environment variables
        sessionVariables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          PAGER = "less -FRX";
        };
      };

      # Enable home-manager self-management
      programs.home-manager.enable = true;

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
      ];
    };
  };
}
