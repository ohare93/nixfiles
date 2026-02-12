{...}: {
  flake.aspects.niri-wm = {
    homeManager = {
      mynix = {
        gui-software.enable = true;
        niri.enable = true;
        eww.enable = true;
        hyprsunset.enable = true;  # For night light toggle in eww
      };
    };
  };
}
