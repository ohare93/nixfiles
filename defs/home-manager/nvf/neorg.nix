{
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    # Neorg plugin configuration
    extraPlugins = {
      neorg = {
        package = pkgs.vimPlugins.neorg;
        setup = ''
          require("neorg").setup({
            load = {
              ["core.defaults"] = {}, -- Load all the default modules
              ["core.concealer"] = { -- Adds pretty icons to your documents
                config = {
                  icon_preset = "diamond",
                },
              },
              ["core.dirman"] = { -- Manages Neorg workspaces
                config = {
                  workspaces = {
                    notes = "~/Notes/neorg-test",
                  },
                  default_workspace = "notes",
                },
              },
              ["core.completion"] = {
                config = {
                  engine = "nvim-cmp",
                },
              },
              ["core.summary"] = {},
              ["core.journal"] = {},
              ["core.export"] = {},
              ["core.keybinds"] = {
                config = {
                  default_keybinds = true,
                },
              },
            },
          })

          -- Set up Neorg autocommands
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "norg",
            callback = function()
              vim.opt_local.conceallevel = 2
              vim.opt_local.concealcursor = "nc"
            end,
          })
        '';
      };

      # Optional: Add neorg-telescope for better integration
      neorg-telescope = {
        package = pkgs.vimPlugins.neorg-telescope;
        setup = ''
          require("neorg").modules.load_module("core.integrations.telescope")
        '';
      };
    };

    # Neorg keymaps
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>nn";
        action = "<cmd>Neorg workspace notes<CR>";
        desc = "Neorg notes workspace";
        silent = true;
      }
      # {
      #   mode = ["n"];
      #   key = "<leader>nw";
      #   action = "<cmd>Neorg workspace work<CR>";
      #   desc = "Neorg work workspace";
      #   silent = true;
      # }
      {
        mode = ["n"];
        key = "<leader>ni";
        action = "<cmd>Neorg index<CR>";
        desc = "Neorg index";
        silent = true;
      }
      {
        mode = ["n"];
        key = "<leader>nj";
        action = "<cmd>Neorg journal today<CR>";
        desc = "Neorg journal today";
        silent = true;
      }
      {
        mode = ["n"];
        key = "<leader>ns";
        action = "<cmd>Neorg generate-workspace-summary<CR>";
        desc = "Neorg workspace summary";
        silent = true;
      }
      {
        mode = ["n"];
        key = "<leader>nt";
        action = "<cmd>Neorg toc<CR>";
        desc = "Neorg table of contents";
        silent = true;
      }

      # Local leader journal keybindings for quick access
      {
        mode = ["n"];
        key = "<localleader>jt";
        action = "<cmd>Neorg journal today<CR>";
        desc = "Journal today";
        silent = true;
      }
      {
        mode = ["n"];
        key = "<localleader>jy";
        action = "<cmd>Neorg journal yesterday<CR>";
        desc = "Journal yesterday";
        silent = true;
      }
      {
        mode = ["n"];
        key = "<localleader>jm";
        action = "<cmd>Neorg journal tomorrow<CR>";
        desc = "Journal tomorrow";
        silent = true;
      }
      {
        mode = ["n"];
        key = "<localleader>jc";
        action = "<cmd>Neorg journal custom<CR>";
        desc = "Journal custom date";
        silent = true;
      }
      {
        mode = ["n"];
        key = "<localleader>jT";
        action = "<cmd>Neorg journal template<CR>";
        desc = "Journal template";
        silent = true;
      }
    ];
  };
}
