{
  pkgs,
  ...
}: {
  beads = pkgs.callPackage ./beads.nix {};
  stmp = pkgs.callPackage ./stmp.nix {};
  zsh-ai-cmd = pkgs.callPackage ./zsh-ai-cmd.nix {};
}
