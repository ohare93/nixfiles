{ inputs, self, ... }:
{
  flake.aspects.host-overton = {
    nixos = { pkgs, config, ... }: {
      imports = [
        self.modules.nixos.nx-podman
        self.modules.nixos.nx-displaylink
        self.modules.nixos.nx-hyprland-system
        self.modules.nixos.nx-battery-protection
        self.modules.nixos.nx-agentic-coding
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
      age.identityPaths = ["/home/jmo/.ssh/agenix"];
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

      # Enable the X11 windowing system.
      services.xserver.enable = true;
      services.libinput = {
        enable = true;
        touchpad.naturalScrolling = true;
      };

      # Enable CUPS to print documents.
      services.printing.enable = true;

      # Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
      };

      # Sudo configuration with password exemptions for common NixOS commands
      security.sudo = {
        enable = true;
        wheelNeedsPassword = true; # Keep password requirement for general sudo
        extraRules = [
          {
            users = ["jmo"];
            commands = [
              {
                command = "/run/current-system/sw/bin/nixos-rebuild *";
                options = ["NOPASSWD"];
              }
              {
                command = "/run/current-system/sw/bin/nix-collect-garbage *";
                options = ["NOPASSWD"];
              }
              {
                command = "/run/current-system/sw/bin/systemctl *";
                options = ["NOPASSWD"];
              }
            ];
          }
        ];
      };

      environment.systemPackages = with pkgs; [
        pcsclite
      ];

      qt = {
        enable = true;
        platformTheme = "kde";
        style = "adwaita-dark";
      };

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
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

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
  };
}
