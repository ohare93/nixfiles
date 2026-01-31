{ inputs, self, pkgs, ... }:
{
  flake.aspects."hatch.host" = {
    nixos = { ... }: {
      imports = [
        self.modules.nixos.nx-podman
        self.modules.nixos.nx-displaylink
        self.modules.nixos.nx-hyprland-system
        self.modules.nixos.nx-desktop-base
        self.modules.nixos.nx-qt-adwaita-dark
        (inputs.self + "/defs/hosts/overton/kanata.nix")
      ];

      system.stateVersion = "25.05";

      # Restart user services that may break during sleep/resume
      powerManagement.resumeCommands = ''
        systemctl --user --machine=jmo@ restart espanso.service || true
      '';

      environment.systemPackages = with pkgs; [
        pcsclite
      ];
    };
  };

  flake.aspects."hatch.home" = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-desktop-base
        self.modules.homeManager.hm-desktop-wm
        self.modules.homeManager.hm-desktop-dev
        self.modules.homeManager.hm-desktop-ai-lite
        self.modules.homeManager.hm-immich
      ];
    };
  };
}
