{
  pkgs,
  ...
}: {
  agent-deck = pkgs.callPackage ./agent-deck.nix {};
  jj-workspace-helper = pkgs.callPackage ./jj-workspace-helper.nix {};
  stmp = pkgs.callPackage ./stmp.nix {};
  zsh-ai-cmd = pkgs.callPackage ./zsh-ai-cmd.nix {};
}
