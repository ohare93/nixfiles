{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options.mynix.uinput = {
    enable = mkEnableOption "uinput support for tools like espanso and kanata";
  };

  config = mkIf config.mynix.uinput.enable {
    # Load the uinput kernel module
    boot.kernelModules = ["uinput"];

    # Enable hardware uinput support
    hardware.uinput.enable = true;

    # Create the uinput group
    users.groups.uinput = {};

    # Create espanso wrapper with CAP_DAC_OVERRIDE capability for Wayland input access
    # Without this capability, espanso fails with "Unable to open EVDEV devices"
    security.wrappers.espanso = {
      source = "${pkgs.espanso-wayland}/bin/espanso";
      capabilities = "cap_dac_override+p";
      owner = "root";
      group = "root";
    };
  };
}
