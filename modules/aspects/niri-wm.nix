{...}: {
  flake.aspects.niri-wm = {
    homeManager = {
      mynix = {
        gui-software.enable = true;
        niri.enable = true;
        eww.enable = true;
        wlsunset.enable = true;  # Night light for Niri (wlr-gamma-control)
      };
    };
  };
}
