{
  ...
}: {
  programs.nvf.settings.vim = {
    # Theme configuration (equivalent to kickstart's tokyonight setup)
    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
    };

    # Status line configuration (equivalent to kickstart's lualine setup)
    statusline.lualine = {
      enable = true;
      theme = "auto";
      # globalstatus = true;
      # You can configure icons here if needed
      # iconsEnabled = true;
    };

    # Telescope fuzzy finder (equivalent to kickstart's telescope setup)
    telescope = {
      enable = true;
      mappings = {
        findFiles = "<leader>sf";
        liveGrep = "<leader>sg";
        buffers = "<leader><leader>";
        helpTags = "<leader>sh";
        # oldFiles = "<leader>s.";
        # currentBufferFuzzyFind = "<leader>/";
        diagnostics = "<leader>sd";
        resume = "<leader>sr";
        # keymaps = "<leader>sk";
      };
      setupOpts = {
        defaults = {
          mappings = {
            n = {
              d = "delete_buffer";
            };
          };
        };
      };
    };

    # Which-key for keybinding hints (equivalent to kickstart's which-key setup)
    binds.whichKey = {
      enable = true;
      register = {
        "<leader>c" = "+[C]ode";
        "<leader>d" = "+[D]ocument";
        "<leader>r" = "+[R]ename";
        "<leader>s" = "+[S]earch";
        "<leader>w" = "+[W]orkspace";
        "<leader>h" = "Git [H]unk";
      };
    };

    # Notifications
    notify.nvim-notify = {
      enable = true;
      setupOpts = {
        stages = "fade";
        timeout = 3000;
      };
    };

    # UI improvements
    ui = {
      borders = {
        enable = true;
        globalStyle = "rounded";
      };
      noice = {
        enable = true;
        setupOpts = {
          lsp = {
            override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
          };
          presets = {
            bottom_search = true;
            command_palette = true;
            long_message_to_split = true;
            inc_rename = false;
            lsp_doc_border = false;
          };
        };
      };
      # Better folding
      nvim-ufo = {
        enable = true;
      };
    };

    # Dashboard (equivalent to kickstart's alpha/dashboard)
    dashboard.alpha = {
      enable = true;
      opts = {
        theme = "dashboard";
      };
    };

    # Indent guides
    visuals.indent-blankline = {
      enable = true;
      setupOpts = {
        indent = {
          char = "│";
        };
        scope = {
          show_start = false;
          show_end = false;
        };
      };
    };

    # Additional visual enhancements
    visuals = {
      # Highlight on yank
      highlight-undo = {
        enable = true;
      };

      # Smooth scrolling
      cinnamon-nvim = {
        enable = true;
      };

      nvim-web-devicons.enable = true;
    };
  };
}
