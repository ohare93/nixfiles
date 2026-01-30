{ inputs, self, pkgs, ... }:
{
  flake.aspects.host-hatch = {
    nixos = { ... }: {
      imports = [
        self.modules.nixos.nx-podman
        self.modules.nixos.nx-displaylink
        self.modules.nixos.nx-hyprland-system
        (inputs.self + "/defs/hosts/overton/kanata.nix")
      ];

      system.stateVersion = "25.05";

      # Restart user services that may break during sleep/resume
      powerManagement.resumeCommands = ''
        systemctl --user --machine=jmo@ restart espanso.service || true
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
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
  };
}
