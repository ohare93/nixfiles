{
  pkgs,
  ...
}: {
  agent-deck = pkgs.callPackage ./agent-deck.nix {};
  stmp = pkgs.callPackage ./stmp.nix {};
  zsh-ai-cmd = pkgs.callPackage ./zsh-ai-cmd.nix {};
}
