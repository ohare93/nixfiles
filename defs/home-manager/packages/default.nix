{
  pkgs,
  ...
}: {
  agent-deck = pkgs.callPackage ./agent-deck.nix {};
  jj-workspace-helper = pkgs.callPackage ./jj-workspace-helper.nix {};
  mcptools = pkgs.callPackage ./mcptools.nix {};
  stmp = pkgs.callPackage ./stmp.nix {};
  zsh-ai-cmd = pkgs.callPackage ./zsh-ai-cmd.nix {};
}
