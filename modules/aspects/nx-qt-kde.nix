{ ... }:
{
  flake.aspects.nx-qt-kde = {
    nixos = { ... }: {
      qt = {
        enable = true;
        platformTheme = "kde";
      };
    };
  };
}
