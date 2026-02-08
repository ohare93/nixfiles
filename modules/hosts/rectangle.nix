{ lib, pkgs, inputs, self, ... }:
{
  flake.aspects."rectangle.host" = {
    nixos = { ... }: {
      # Hostname
      networking.hostName = "rectangle";

      # Enable NetworkManager for WiFi
      networking.networkmanager.enable = true;

      # Ensure wireless support is enabled
      networking.wireless.enable = lib.mkForce false; # NetworkManager handles this

      # X11 with minimal window manager
      services.xserver = {
        enable = true;

        # Danish keyboard layout
        xkb = {
          layout = "dk";
          variant = "";
        };

        # Use modesetting driver for VC4 GPU acceleration
        videoDrivers = ["modesetting"];

        # Disable screen blanking and DPMS (Display Power Management Signaling)
        # Prevents screen from going to sleep during media playback
        serverFlagsSection = ''
          Option "BlankTime" "0"
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
          Option "DPMS" "false"
        '';

        windowManager.i3.enable = true;
        displayManager.lightdm.enable = true;

        # Disable X screensaver and DPMS (runs before window manager starts)
        # Fixes NixOS 24.05 screen blanking issue
        displayManager.setupCommands = ''
          ${pkgs.xorg.xset}/bin/xset s off
          ${pkgs.xorg.xset}/bin/xset -dpms
          ${pkgs.xorg.xset}/bin/xset s noblank
        '';
      };

      # Auto-login to get to desktop quickly
      services.displayManager.autoLogin = {
        enable = true;
        user = "jmo";
      };

      # Audio with pipewire (crucial for both Moonlight and Jellyfin)
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        # 32-bit support is not available on aarch64
        alsa.support32Bit = false;
        pulse.enable = true;
        # Enable JACK support for low-latency audio if needed
        jack.enable = true;
      };

      # Enable OpenSSH for remote access
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };

      mynix.ssh.ca = {
        enable = true;
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAGMME41mVJTB8zrubSIJcsYV2KGXc9FHguwULRd4f1 jmo-ssh-user-ca";
        authorizedPrincipalsFile = "/etc/ssh/auth_principals/%u";
      };

      environment.etc."ssh/auth_principals/jmo".text = "jmo\n";

      # Enable XRDP for remote desktop access via Remmina
      services.xrdp = {
        enable = true;
        defaultWindowManager = "i3";
        openFirewall = true;
      };

      # Enable console login on tty1 with auto-login
      services.getty = {
        autologinUser = "jmo";
        helpLine = "Rectangle - Raspberry Pi 5 Streaming Client";
      };

      # Prevent system from sleeping/suspending on idle
      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        IdleAction = "ignore";
      };

      # Streaming and media packages
      environment.systemPackages = with pkgs; [
        # Game streaming client
        moonlight-qt

        # Movie/media streaming client
        jellyfin-media-player

        # Web browser with GPU acceleration for Raspberry Pi 5
        # Note: ARM doesn't support VAAPI - Pi 5 uses V4L2 (not included in standard Chromium)
        (chromium.override {
          commandLineArgs = [
            # GPU rendering acceleration (works with modesetting driver)
            "--enable-features=CanvasOopRasterization"
            "--enable-gpu-rasterization"
            "--enable-zero-copy"
            "--use-gl=egl"

            # Ignore GPU blocklist (Raspberry Pi often blocked)
            "--ignore-gpu-blocklist"

            # Enable hardware overlays
            "--enable-hardware-overlays"
          ];
        })

        # Terminal emulator for i3
        alacritty

        # Application launcher for i3
        dmenu

        # Useful debugging tools
        pciutils
        usbutils
        htop

        # Hardware video acceleration tools
        libva-utils # vainfo command
        v4l-utils # v4l2 video utilities
      ];

      # GnuPG with SSH support
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      # User configuration
      users.users.jmo = {
        isNormalUser = true;
        description = inputs.private.identity.fullName;
        extraGroups = ["wheel" "networkmanager" "audio" "video"];
        openssh.authorizedKeys.keys = [
          # Add your SSH public key here after first boot
        ];
      };

      # Sudo without password for wheel group
      security.sudo.enable = true;
      security.sudo.wheelNeedsPassword = false;
    };
  };

  flake.aspects."rectangle.home" = {
    homeManager = { lib, pkgs, inputs, ... }: {
      imports = [
        self.modules.homeManager.hm-shells
        self.modules.homeManager.hm-kitty
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
      ];

      programs.jujutsu.package = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.jujutsu;

      mynix = {
        i3.enable = true;
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
    };
  };
}
