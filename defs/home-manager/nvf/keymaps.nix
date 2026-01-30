{
  ...
}: {
  programs.nvf.settings.vim = {
    keymaps = [
      # Clear search highlights
      {
        key = "<Esc>";
        mode = ["n"];
        action = ":nohlsearch<CR>";
        silent = true;
        desc = "Clear highlights on search when pressing <Esc> in normal mode";
      }

      # Open diagnostic quickfix list
      {
        key = "<leader>q";
        mode = ["n"];
        action = "<cmd>lua vim.diagnostic.setloclist()<CR>";
        desc = "Open diagnostic [Q]uickfix list";
      }

      # Exit terminal mode
      {
        key = "<Esc><Esc>";
        mode = ["t"];
        action = "<C-\\><C-n>";
        desc = "Exit terminal mode";
      }

      # Window navigation
      {
        key = "<C-h>";
        mode = ["n"];
        action = "<C-w><C-h>";
        desc = "Move focus to the left window";
      }
      {
        key = "<C-l>";
        mode = ["n"];
        action = "<C-w><C-l>";
        desc = "Move focus to the right window";
      }
      {
        key = "<C-j>";
        mode = ["n"];
        action = "<C-w><C-j>";
        desc = "Move focus to the lower window";
      }
      {
        key = "<C-k>";
        mode = ["n"];
        action = "<C-w><C-k>";
        desc = "Move focus to the upper window";
      }

      # Swap to last open buffer
      {
        key = "<leader>k";
        mode = ["n"];
        action = ":e#<CR>";
        silent = true;
        desc = "Switch to previous buffer";
      }

      # Cut/Delete without registry
      {
        key = "x";
        mode = ["n" "v"];
        action = "\"_x";
        desc = "Cut without adding to registry";
      }
      {
        key = "X";
        mode = ["n"];
        action = "\"_X";
        desc = "Delete without adding to registry";
      }
      {
        key = "XX";
        mode = ["n"];
        action = "\"_dd";
        desc = "Delete whole line without adding to registry";
      }

      # Reload vimrc
      {
        key = "<leader>vv";
        mode = ["n"];
        action = ":source $MYVIMRC<CR>";
        desc = "Reload vimrc";
      }

      # Telescope keybindings
      {
        key = "<leader>sh";
        mode = ["n"];
        action = "<cmd>Telescope help_tags<CR>";
        desc = "Search Help";
      }
      {
        key = "<leader>sk";
        mode = ["n"];
        action = "<cmd>Telescope keymaps<CR>";
        desc = "Search Keymaps";
      }
      {
        key = "<leader>sf";
        mode = ["n"];
        action = "<cmd>Telescope find_files<CR>";
        desc = "Search Files";
      }
      {
        key = "<leader>ss";
        mode = ["n"];
        action = "<cmd>Telescope builtin<CR>";
        desc = "Search Select Telescope";
      }
      {
        key = "<leader>sw";
        mode = ["n"];
        action = "<cmd>Telescope grep_string<CR>";
        desc = "Search current Word";
      }
      {
        key = "<leader>sg";
        mode = ["n"];
        action = "<cmd>Telescope live_grep<CR>";
        desc = "Search by Grep";
      }
      {
        key = "<leader>sd";
        mode = ["n"];
        action = "<cmd>Telescope diagnostics<CR>";
        desc = "Search Diagnostics";
      }
      {
        key = "<leader>sr";
        mode = ["n"];
        action = "<cmd>Telescope resume<CR>";
        desc = "Search Resume";
      }
      {
        key = "<leader>s.";
        mode = ["n"];
        action = "<cmd>Telescope oldfiles<CR>";
        desc = "Search Recent Files";
      }
      {
        key = "<leader><leader>";
        mode = ["n"];
        action = "<cmd>Telescope buffers<CR>";
        desc = "Find existing buffers";
      }
      {
        key = "<leader>sc";
        mode = ["n"];
        action = "<cmd>Telescope commands<CR>";
        desc = "Search Commands";
      }
      {
        key = "<leader>sC";
        mode = ["n"];
        action = "<cmd>Telescope command_history<CR>";
        desc = "Search Command History";
      }
      {
        key = "<leader>/";
        mode = ["n"];
        action = "<cmd>Telescope current_buffer_fuzzy_find<CR>";
        desc = "Fuzzily search in current buffer";
      }
      {
        key = "<leader>s/";
        mode = ["n"];
        action = "<cmd>Telescope live_grep grep_open_files=true<CR>";
        desc = "Live Grep in Open Files";
      }
      {
        key = "<leader>sn";
        mode = ["n"];
        action = "<cmd>Telescope find_files cwd=~/nixfiles/defs/home-manager/nvf<CR>";
        desc = "Search Neovim files";
      }

      # LSP debugging keymaps
      {
        key = "<leader>li";
        mode = ["n"];
        action = "<cmd>LspInfo<CR>";
        desc = "LSP Info";
      }
      {
        key = "<leader>lk";
        mode = ["n"];
        action = "<cmd>lua print(vim.inspect(vim.lsp.get_active_clients()))<CR>";
        desc = "Show active LSP clients";
      }
      {
        key = "<leader>lc";
        mode = ["n"];
        action = "<cmd>lua local clients = vim.lsp.get_active_clients({bufnr = 0}); for _, client in ipairs(clients) do if client.server_capabilities.documentFormattingProvider then print(client.name .. ' supports formatting') else print(client.name .. ' does NOT support formatting') end end<CR>";
        desc = "Check LSP formatting capabilities";
      }

      # Robust formatting keymaps (fallback strategy)
      {
        key = "<leader>lf";
        mode = ["n"];
        action = "<cmd>lua local clients = vim.lsp.get_active_clients({bufnr = 0}); local has_formatter = false; for _, client in ipairs(clients) do if client.server_capabilities.documentFormattingProvider then has_formatter = true; break end end; if has_formatter then vim.lsp.buf.format() else print('No LSP formatter available for this buffer') end<CR>";
        desc = "Format buffer (LSP with fallback)";
      }
    ];
  };
}
