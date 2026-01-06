{
  ...
}: {
  programs.nvf.settings.vim = {
    autocomplete = {
      nvim-cmp = {
        enable = true;

        # Mappings for completion
        mappings = {
          complete = "<C-Space>";
          confirm = "<CR>";
          next = "<Tab>";
          previous = "<S-Tab>";
          close = "<C-e>";
          scrollDocsUp = "<C-u>";
          scrollDocsDown = "<C-d>";
        };

        # Sources for completion - only LSP and snippets, no buffer completion
        # sources = {
        #   nvim_lsp = { };
        #   luasnip = { };
        #   path = { };  # Keep path completion for file paths
        # };

        # Completion formatting
        # format = {
        #   enable = true;
        #   # fields order
        #   fields = ["abbr" "kind" "menu"];
        # };

        # Completion window appearance
        setupOpts = {
          window = {
            completion = {
              border = "rounded";
              winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None";
              col_offset = -3;
              side_padding = 0;
            };
            documentation = {
              border = "rounded";
              max_height = 15;
              max_width = 60;
            };
          };

          # Completion behavior
          completion = {
            completeopt = "menu,menuone,noinsert";
          };

          # Confirmation behavior
          confirmation = {
            default_behavior = "cmp.ConfirmBehavior.Replace";
            # get_commit_characters = function(commit_characters)
            #   return {};
            # end;
          };
        };
      };
    };

    # Snippet configuration (equivalent to kickstart's luasnip setup)
    snippets.luasnip = {
      enable = true;

      providers = ["friendly-snippets"];

      # Custom snippet paths (if you have any)
      # paths = [
      #   ./snippets
      # ];
    };

    # Additional completion sources and enhancements

    # LSP kind icons for better completion display
    lsp.lspkind = {
      enable = true;
      setupOpts = {
        mode = "symbol_text";
        preset = "codicons";
        symbol_map = {
          Text = "󰉿";
          Method = "󰆧";
          Function = "󰊕";
          Constructor = "";
          Field = "󰜢";
          Variable = "󰀫";
          Class = "󰠱";
          Interface = "";
          Module = "";
          Property = "󰜢";
          Unit = "󰑭";
          Value = "󰎠";
          Enum = "";
          Keyword = "󰌋";
          Snippet = "";
          Color = "󰏘";
          File = "󰈙";
          Reference = "󰈇";
          Folder = "󰉋";
          EnumMember = "";
          Constant = "󰏿";
          Struct = "󰙅";
          Event = "";
          Operator = "󰆕";
          TypeParameter = "";
        };
      };
    };

    # Autopairs for automatic bracket completion
    autopairs.nvim-autopairs = {
      enable = true;
      setupOpts = {
        check_ts = true; # Enable treesitter integration
        ts_config = {
          lua = ["string" "source"];
          javascript = ["string" "template_string"];
          java = false;
        };
        disable_filetype = ["TelescopePrompt" "vim"];
        disable_in_macro = false;
        disable_in_visualblock = false;
        disable_in_replace_mode = true;
        # ignored_next_char = string.gsub("[%w%%%'%[%\"%.%`%$]" "%." "%%.");
        enable_moveright = true;
        enable_afterquote = true;
        enable_check_bracket_line = true;
        enable_bracket_in_quote = true;
        enable_abbr = false;
        break_undo = true;
        check_comma = true;
        map_cr = true;
        map_bs = true;
        map_c_h = false;
        map_c_w = false;
      };
    };

    # Surround functionality
    utility.surround = {
      enable = true;
      useVendoredKeybindings = true;
    };

    # Comments
    comments.comment-nvim = {
      enable = true;
      mappings = {
        toggleCurrentLine = "gcc";
        toggleCurrentBlock = "gbc";
      };
    };

    # Disable treesitter completion source for prose/non-code filetypes
    # and enable spell checking
    luaConfigRC.prose-mode = ''
      -- Ensure spell directory exists and set spellfile for personal dictionary
      local spell_dir = vim.fn.stdpath("data") .. "/spell"
      vim.fn.mkdir(spell_dir, "p")
      vim.opt.spellfile = spell_dir .. "/en.utf-8.add"

      local prose_filetypes = {
        "typst", "markdown", "text", "txt", "plaintex", "tex",
        "rst", "asciidoc", "org", "norg", "mail", "gitcommit"
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = prose_filetypes,
        callback = function()
          -- Enable spell checking for prose
          vim.opt_local.spell = true
          vim.opt_local.spelllang = "en_gb"

          local cmp = require("cmp")
          local config = cmp.get_config()

          -- Filter out treesitter source
          local filtered_sources = {}
          for _, source in ipairs(config.sources or {}) do
            if source.name ~= "treesitter" then
              table.insert(filtered_sources, source)
            end
          end

          -- Apply filtered sources for this buffer
          cmp.setup.buffer({ sources = filtered_sources })
        end,
      })
    '';
  };
}
