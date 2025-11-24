{
  pkgs,
  ...
}: {
  beads = pkgs.callPackage ./beads.nix {};
}
