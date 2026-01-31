{ ... }:
{
  flake.aspects.nx-qt-adwaita-dark = {
    nixos = { ... }: {
      qt = {
        enable = true;
        platformTheme = "kde";
        style = "adwaita-dark";
      };
    };
  };
}
