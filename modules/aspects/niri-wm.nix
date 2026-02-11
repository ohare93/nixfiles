{...}: {
  flake.aspects.niri-wm = {
    homeManager = {
      mynix = {
        gui-software.enable = true;
        niri.enable = true;
      };
    };
  };
}
