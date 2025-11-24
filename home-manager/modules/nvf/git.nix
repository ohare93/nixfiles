{
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    # Add jj-diffconflicts plugin for jujutsu conflict resolution
    startPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "jj-diffconflicts";
        src = pkgs.fetchFromGitHub {
          owner = "rafikdraoui";
          repo = "jj-diffconflicts";
          rev = "1e98328054902209a5338ec80f26b8e8a13cfb26";
          sha256 = "sha256-H7HF7tuSctnU+Qk+k1sPd/i9cLnQb1jBxRQxwYNpTao=";
        };
      })
    ];

    git = {
      enable = true;
      gitsigns = {
        enable = true;
        codeActions.enable = true;

        # Git signs configuration
        setupOpts = {
          signs = {
            add = {text = "+";};
            change = {text = "~";};
            delete = {text = "_";};
            topdelete = {text = "‾";};
            changedelete = {text = "~";};
            untracked = {text = "┆";};
          };

          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 1000;
            ignore_whitespace = false;
          };
        };
      };
    };
  };
}
