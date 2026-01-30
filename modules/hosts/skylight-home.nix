{ self, ... }:
{
  flake.aspects.home-skylight = {
    homeManager = { lib, pkgs, inputs, ... }: {
      imports = [
        self.modules.homeManager.hm-shells
      ];

      home.packages = [
        inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.jujutsu
      ];

      programs.jujutsu.enable = lib.mkForce false;

      mynix = {
        nushell.enable = false;

        terminal-misc = {
          zoxide.enable = true;
          zellij.enable = true;
          atuin.enable = true;
          fzf.enable = false;
          carapace.enable = false;
          claude.enable = false;
          devbox.enable = false;
          comma.enable = false;
          nvd.enable = false;
          gren.enable = false;
          poetry.enable = false;
          opencode.enable = false;
        };

        devbox.enable = false;
        television.enable = false;
        yazi.enable = false;
        ssh.enable = true;
        gui-software.enable = false;
        hyprland.enable = false;
        syncthing.enable = false;
        notes.zk.enable = false;
        qutebrowser.enable = false;
      };

      programs.nvf.enable = lib.mkForce false;

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        extraConfig = ''
          set number
          set expandtab
          set tabstop=2
          set shiftwidth=2
        '';
      };
    };
  };
}
