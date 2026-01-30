{
  lib,
  pkgs,
  ...
}: let
  # Check if opencode-nvim is available in vimPlugins
  hasOpencode = pkgs.vimPlugins ? opencode-nvim;
  hasSnacks = pkgs.vimPlugins ? snacks-nvim;
in {
  programs.nvf.settings = {
    # Enable CodeCompanion.nvim assistant
    vim.assistant.codecompanion-nvim = {
      enable = true;

      setupOpts = {
        default_adapter = "anthropic";

        # Display configuration
        display = {
          action_palette = {
            width = 95;
            height = 10;
          };
          chat = {
            window = {
              layout = "vertical";
              border = "rounded";
              width = 0.45;
              height = 0.8;
            };
            show_settings = true;
          };
        };

        strategies = {
          chat = {
            adapter = "anthropic";
          };
          inline = {
            adapter = "anthropic";
          };
          agent = {
            adapter = "anthropic";
          };
        };
      };
    };

    # Configure keymaps for CodeCompanion
    vim.keymaps = [
      {
        key = "<leader>cc";
        action = "<cmd>CodeCompanionActions<cr>";
        mode = ["n" "v"];
        desc = "CodeCompanion Actions";
        silent = true;
      }
      {
        key = "<leader>ch";
        action = "<cmd>CodeCompanionChat Toggle<cr>";
        mode = ["n" "v"];
        desc = "Toggle CodeCompanion Chat";
        silent = true;
      }
      {
        key = "<leader>ce";
        action = "<cmd>CodeCompanionChat Add<cr>";
        mode = ["v"];
        desc = "Add selection to CodeCompanion Chat";
        silent = true;
      }
    ];

    # Add command abbreviation
    # vim.extraConfigLua = ''
    #   -- Expand 'cc' into CodeCompanionChat
    #   vim.cmd([[cab cc CodeCompanionChat]])
    # '';

    # opencode.nvim integration (only if available)
    vim.startPlugins = lib.optionals (hasSnacks && hasOpencode) [
      pkgs.vimPlugins.snacks-nvim # Required dependency for opencode.nvim
      pkgs.vimPlugins.opencode-nvim
    ];

    vim.extraPlugins = lib.optionalAttrs hasOpencode {
      opencode-nvim = {
        package = pkgs.vimPlugins.opencode-nvim;
        setup = ''
          -- Setup snacks.nvim dependency
          require("snacks").setup({
            input = {},
            picker = {},
          })

          -- Configure opencode.nvim
          vim.g.opencode_opts = {
            -- Configuration can be added here as needed
            -- See lua/opencode/config.lua in the plugin repo
          }

          -- Required for vim.g.opencode_opts.auto_reload
          vim.opt.autoread = true

          -- Keymaps for opencode.nvim
          vim.keymap.set({ "n", "x" }, "<leader>oa", function()
            require("opencode").ask("@this: ", { submit = true })
          end, { desc = "OpenCode: Ask about this" })

          vim.keymap.set({ "n", "x" }, "<leader>os", function()
            require("opencode").select()
          end, { desc = "OpenCode: Select prompt" })

          vim.keymap.set({ "n", "x" }, "<leader>oc", function()
            require("opencode").prompt("@this")
          end, { desc = "OpenCode: Add this to context" })

          vim.keymap.set("n", "<leader>ot", function()
            require("opencode").toggle()
          end, { desc = "OpenCode: Toggle embedded" })
        '';
      };
    };
  };
}
