{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nvf.homeManagerModules.default
    ./ui.nix
    ./completion.nix
    ./lsp.nix
    ./git.nix
    ./utility.nix
    ./ai.nix
    ./keymaps.nix
    ./neorg.nix
  ];

  # Basic vim options equivalent to kickstart's options.lua
  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        # Basic vim options
        viAlias = false;
        vimAlias = true;

        # Leader key setup
        globals.mapleader = " ";
        globals.maplocalleader = ",";

        # Basic options equivalent to kickstart's vim.opt settings
        options = {
          # Line numbers
          number = true;
          relativenumber = true;

          # Mouse support
          mouse = "a";

          # Clipboard integration
          clipboard = "unnamedplus";

          # Indentation
          expandtab = true;
          tabstop = 2;
          softtabstop = 2;
          shiftwidth = 2;
          smartindent = true;

          # Search settings
          ignorecase = true;
          smartcase = true;
          incsearch = true;
          hlsearch = false;

          # Split behavior
          splitright = true;
          splitbelow = true;

          # Display settings
          showmode = false;
          breakindent = true;
          cursorline = true;

          # Whitespace characters
          list = true;

          # Undo settings
          undofile = true;

          # Update time
          updatetime = 250;
          timeoutlen = 300;

          # Sign column
          signcolumn = "yes";

          # Scrolling
          scrolloff = 10;

          # Confirmation dialog
          confirm = true;

          # Preview substitutions
          inccommand = "split";

          # Color settings
          termguicolors = true;
        };

        # Package to use
        package = pkgs.neovim-unwrapped;

        # Configure clipboard for Wayland
        luaConfigRC.clipboard = ''
          -- Use wl-clipboard for Wayland
          if os.getenv("WAYLAND_DISPLAY") then
            vim.g.clipboard = {
              name = "wl-clipboard",
              copy = {
                ["+"] = "wl-copy",
                ["*"] = "wl-copy",
              },
              paste = {
                ["+"] = "wl-paste --no-newline",
                ["*"] = "wl-paste --no-newline",
              },
              cache_enabled = 1,
            }
          end
        '';

        # Configure listchars
        luaConfigRC.listchars = ''
          vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
        '';
      };
    };
  };
}
