{
  pkgs,
  ...
}: {
  agent-deck = pkgs.callPackage ./agent-deck.nix {};
  beads = pkgs.callPackage ./beads.nix {};
  stmp = pkgs.callPackage ./stmp.nix {};
}
