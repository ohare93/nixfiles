{ lib, pkgs, self, ... }:
{
  flake.aspects."aperture.host" = {
    nixos = { ... }: {
      imports = [
        self.modules.nixos.nx-battery-protection
        self.modules.nixos.nx-uinput
        self.modules.nixos.nx-desktop-base
        self.modules.nixos.nx-plasma
        self.modules.nixos.nx-qt-kde
      ];

      system.stateVersion = "25.05";

      # Disable power-profiles-daemon (conflicts with TLP from battery-protection)
      # nixos-hardware Surface module enables this by default
      services.power-profiles-daemon.enable = lib.mkForce false;

      # Surface-specific packages
      environment.systemPackages = with pkgs; [
        # Useful for debugging hardware
        pciutils
        usbutils
      ];
    };
  };

  flake.aspects."aperture.home" = {
    homeManager = { ... }: {
      imports = [
        self.modules.homeManager.hm-desktop-base
        self.modules.homeManager.hm-desktop-plasma
        self.modules.homeManager.hm-desktop-dev
        self.modules.homeManager.hm-desktop-ai-lite
      ];
    };
  };
}
