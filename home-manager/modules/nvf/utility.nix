{
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    # Add vim-unimpaired for bracket mappings
    startPlugins = [
      pkgs.vimPlugins.vim-unimpaired
    ];

    # Utility plugins and configurations

    utility.oil-nvim = {
      enable = true;
      setupOpts = {
        default_file_explorer = true;
        columns = [
          "icon"
          # "permissions"
          # "size"
          # "mtime"
        ];
        delete_to_trash = true;
        skip_confirm_for_simple_edits = true;
        constrain_cursor = "editable";
        experimental_watch_for_changes = false;
        view_options = {
          show_hidden = true;
          natural_order = true;
          sort = {
            type = "asc";
            name = "asc";
          };
        };
      };
    };
    keymaps = [
      {
        # vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
        key = "-";
        mode = ["n"];
        action = "<CMD>Oil<CR>";
        silent = true;
        desc = "Open parend directory";
      }
      # Persistence session management keymaps (will be added after extraPlugins)
    ];

    # Mini.nvim plugins (equivalent to kickstart's mini setup)
    mini = {
      # Better Around/Inside textobjects
      ai = {
        enable = true;
        setupOpts = {
          n_lines = 500;
        };
      };

      # Add/delete/replace surroundings (brackets, quotes, etc.)
      surround = {
        enable = true;
      };

      # Simple and easy statusline
      statusline = {
        enable = false; # Disabled since we're using lualine
      };

      # Better buffer deletion
      bufremove = {
        enable = true;
      };

      # File picker
      pick = {
        enable = false; # Disabled since we're using telescope
      };

      # Better f/F/t/T functionality
      # jump = {
      #   enable = true;
      # };

      # Highlight patterns in buffer
      hipatterns = {
        enable = true;
      };

      # Icons
      icons = {
        enable = true;
      };

      # Indentation scope visualization
      indentscope = {
        enable = true;
        setupOpts = {
          symbol = "│";
          options = {try_as_border = true;};
        };
      };

      # Better increment/decrement
      splitjoin = {
        enable = true;
      };
    };

    # Motion plugins
    utility.motion = {
      flash-nvim = {
        enable = true;
      };
    };

    # Terminal integration
    terminal.toggleterm = {
      enable = true;
      mappings.open = "<C-\\>";
      setupOpts = {
        size = 20;
        open_mapping = "<C-\\>";
        hide_numbers = true;
        shade_filetypes = {};
        shade_terminals = true;
        shading_factor = 2;
        start_in_insert = true;
        insert_mappings = true;
        persist_size = true;
        direction = "float";
        close_on_exit = true;
        # shell = vim.o.shell;
        float_opts = {
          border = "curved";
          winblend = 0;
          highlights = {
            border = "Normal";
            background = "Normal";
          };
        };
      };
    };

    # Session management with Persistence.nvim
    extraPlugins = {
      persistence = {
        package = pkgs.vimPlugins.persistence-nvim;
        setup = ''
          require("persistence").setup({
            dir = vim.fn.stdpath("state") .. "/sessions/",
            need = 1,
            branch = true,
          })

          -- Directories where sessions should not be saved or restored
          local home = vim.fn.expand("~")
          local disabled_dirs = {
            home,
            home .. "/Downloads",
            home .. "/Desktop",
            "/",
            "/tmp",
          }

          local group = vim.api.nvim_create_augroup("Persistence", { clear = true })

          -- Autosave session on exit
          vim.api.nvim_create_autocmd("VimLeavePre", {
            group = group,
            callback = function()
              local cwd = vim.fn.getcwd()
              for _, path in pairs(disabled_dirs) do
                if path == cwd then
                  return
                end
              end
              require("persistence").save()
            end,
          })

          -- Auto-restore session when entering vim without arguments
          vim.api.nvim_create_autocmd("VimEnter", {
            group = group,
            callback = function()
              local cwd = vim.fn.getcwd()

              for _, path in pairs(disabled_dirs) do
                if path == cwd then
                  require("persistence").stop()
                  return
                end
              end

              if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
                require("persistence").load()
              else
                require("persistence").stop()
              end
            end,
            nested = true,
          })

          -- Keymaps for persistence
          vim.keymap.set("n", "<leader>qs", function() require("persistence").save() end, { desc = "Save session" })
          vim.keymap.set("n", "<leader>qS", function() require("persistence").select() end, { desc = "Select session" })
          vim.keymap.set("n", "<leader>ql", function() require("persistence").load() end, { desc = "Load session for current directory" })
          vim.keymap.set("n", "<leader>qL", function() require("persistence").load({ last = true }) end, { desc = "Load last session" })
          vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Stop persistence (don't save on exit)" })
        '';
      };
    };

    # Project management
    projects.project-nvim = {
      enable = true;
      setupOpts = {
        detection_methods = ["lsp" "pattern"];
        patterns = [".git" ".jj" "_darcs" ".hg" ".bzr" ".svn" "Makefile" "package.json" "flake.nix"];
        ignore_lsp = {};
        exclude_dirs = [];
        show_hidden = false;
        silent_chdir = true;
        scope_chdir = "global";
      };
    };

    # Todo comments highlighting
    notes.todo-comments = {
      enable = true;
      # mappings = {
      #   todoTrouble = "<leader>xt";
      #   todoTelescope = "<leader>st";
      #   todoLocList = "<leader>xL";
      #   todoQuickFix = "<leader>xQ";
      # };
    };

    # Markdown preview (if working with markdown)
    utility.preview = {
      glow = {
        enable = true;
      };
    };

    # Additional keymaps for utilities
    # keymaps = [
    #   # Clear search highlighting
    #   {
    #     mode = "n";
    #     key = "<Esc>";
    #     action = "<cmd>nohlsearch<CR>";
    #     options = {
    #       desc = "Clear search highlighting";
    #       silent = true;
    #     };
    #   }
    #
    #   # Diagnostic keymaps
    #   {
    #     mode = "n";
    #     key = "[d";
    #     action = "vim.diagnostic.goto_prev";
    #     options = {
    #       desc = "Go to previous diagnostic message";
    #       silent = true;
    #     };
    #   }
    #
    #   {
    #     mode = "n";
    #     key = "]d";
    #     action = "vim.diagnostic.goto_next";
    #     options = {
    #       desc = "Go to next diagnostic message";
    #       silent = true;
    #     };
    #   }
    #
    #   # Buffer navigation
    #   {
    #     mode = "n";
    #     key = "<Tab>";
    #     action = "<cmd>bnext<CR>";
    #     options = {
    #       desc = "Next buffer";
    #       silent = true;
    #     };
    #   }
    #
    #   {
    #     mode = "n";
    #     key = "<S-Tab>";
    #     action = "<cmd>bprevious<CR>";
    #     options = {
    #       desc = "Previous buffer";
    #       silent = true;
    #     };
    #   }
    #
    #   # Window management
    #   {
    #     mode = "n";
    #     key = "<leader>wv";
    #     action = "<cmd>vsplit<CR>";
    #     options = {
    #       desc = "Split window vertically";
    #       silent = true;
    #     };
    #   }
    #
    #   {
    #     mode = "n";
    #     key = "<leader>wh";
    #     action = "<cmd>split<CR>";
    #     options = {
    #       desc = "Split window horizontally";
    #       silent = true;
    #     };
    #   }
    #
    #   {
    #     mode = "n";
    #     key = "<leader>wq";
    #     action = "<cmd>close<CR>";
    #     options = {
    #       desc = "Close window";
    #       silent = true;
    #     };
    #   }
    #
    #   # Quick save
    #   {
    #     mode = "n";
    #     key = "<leader>w";
    #     action = "<cmd>write<CR>";
    #     options = {
    #       desc = "Save file";
    #       silent = true;
    #     };
    #   }
    # ];
  };
}
