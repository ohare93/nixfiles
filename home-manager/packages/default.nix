{
  pkgs,
  ...
}: {
  beads = pkgs.callPackage ./beads.nix {};
  stmp = pkgs.callPackage ./stmp.nix {};
}
