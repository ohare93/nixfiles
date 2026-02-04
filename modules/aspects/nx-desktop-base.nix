{ ... }:
{
  flake.aspects.nx-desktop-base = {
    nixos = { ... }: {
      # Enable the X11 windowing system.
      services.xserver.enable = true;

      # Touchpad support
      services.libinput = {
        enable = true;
        touchpad.naturalScrolling = true;
      };

      # Printing support
      services.printing.enable = true;

      # Audio with pipewire
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      # Sudo configuration - require password for dangerous system commands
      # NOTE: nixos-rebuild explicitly requires password to prevent accidental
      # application of wrong configs (e.g., VPS config on desktop)
      security.sudo = {
        enable = true;
        wheelNeedsPassword = true;
        extraRules = [
          {
            users = ["jmo"];
            commands = [
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

      # GnuPG with SSH support
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
  };
}
