{...}: {
  flake.aspects.wm = {
    homeManager = {
      mynix = {
        gui-software.enable = true;
        hyprland.enable = true;
        gammastep.enable = true;
      };
    };
  };
}
