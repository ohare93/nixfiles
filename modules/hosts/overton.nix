{ inputs, self, ... }:
{
  flake.aspects."overton.host" = {
    nixos = { pkgs, config, hostname, ... }: {
      imports = [
        self.modules.nixos.nx-podman
        self.modules.nixos.nx-displaylink
        self.modules.nixos.nx-hyprland-system
        self.modules.nixos.nx-battery-protection
        self.modules.nixos.nx-agentic-coding
        self.modules.nixos.nx-desktop-base
        self.modules.nixos.nx-qt-adwaita-dark
        (inputs.self + "/defs/hosts/overton/kanata.nix")
      ];

      system.stateVersion = "25.05";

      # Add nixos-raspberrypi binary cache for cross-compilation
      nix.settings = {
        substituters = [
          "https://nixos-raspberrypi.cachix.org"
        ];
        trusted-public-keys = [
          "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
        # Allow jmo to use binary caches
        trusted-users = ["root" "jmo"];
      };

      # Agenix configuration
      age.identityPaths = ["/home/jmo/.ssh/age_${hostname}"];
      age.secrets.overton-signing-key = {
        file = inputs.self + "/secrets/overton-signing-key.age";
        mode = "400";
      };

      mynix = {
        battery-protection = {
          upower.criticalPowerAction = "Ignore"; # Disable auto-sleep at 35%
        };

        # Sign all built paths so other machines can receive them
        nix-signing = {
          enableSigning = true;
          signingKeyFile = config.age.secrets.overton-signing-key.path;
        };
      };

      # Restart user services that lose connections during sleep/resume
      powerManagement.resumeCommands = ''
        systemctl --user --machine=jmo@ restart ntfy-notifications.service || true
        systemctl --user --machine=jmo@ restart espanso.service || true
      '';

      # Open port for ttyd (web terminal for zellij access from phone)
      networking.firewall.allowedTCPPorts = [7681];

      # udev rule for automatic monitor hotplug detection
      # Triggers hypr-display-switcher service when monitors are plugged/unplugged
      services.udev.extraRules = ''
        ACTION=="change", SUBSYSTEM=="drm", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="hypr-display-switcher.service"
      '';

      environment.systemPackages = with pkgs; [
        pcsclite
      ];
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # Electron / GTK dependencies
          glib
          nss
          nspr
          atk
          cups
          dbus
          libdrm
          gtk3
          pango
          cairo
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
          xorg.libxcb
          mesa
          libgbm
          xorg.libxshmfence
          xorg.libXcursor
          xorg.libXi
          xorg.libXrender
          xorg.libXtst
          pciutils
          expat
          alsa-lib
          at-spi2-atk
          at-spi2-core
          libxkbcommon
          libglvnd
        ];
      };

    };
  };

  flake.aspects."overton.home" = {
    homeManager = { lib, ... }: {
      imports = [
        self.modules.homeManager.hm-desktop-base
        self.modules.homeManager.hm-desktop-wm
        self.modules.homeManager.hm-desktop-dev
        self.modules.homeManager.hm-desktop-ai-full
        self.modules.homeManager.hm-stmp
        self.modules.homeManager.hm-bitwarden
        self.modules.homeManager.hm-typst
        self.modules.homeManager.hm-self-employed
      ];

      programs.zellij.enableZshIntegration = lib.mkForce false;
    };
  };
}
