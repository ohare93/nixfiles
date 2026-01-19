{
  lib,
  config,
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
  };
}
