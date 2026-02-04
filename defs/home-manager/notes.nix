{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.mynix.notes;
in
  with lib; {
    options.mynix.notes = {
      zk.enable = mkEnableOption "zk";
    };

    config = {
      programs = {
        zk = mkIf cfg.zk.enable {
          enable = true;
          settings = {
            notebook = {
              dir = "~/notebook";
            };

            note = {
              language = "en";
              default-title = "Untitled";
              filename = "{{id}}-{{slug title}}";
              extension = "md";
              template = "default.md";
              id = {
                charset = "alphanum";
                length = 4;
                case = "lower";
              };
            };

            extra = {
              author = inputs.private.identity.firstName;
            };

            group = {
              journal = {
                paths = ["journal/weekly" "journal/daily"];
                note = {
                  filename = "{{format-date now}}";
                };
              };
            };

            format = {
              markdown = {
                hashtags = true;
                colon-tags = true;
              };
            };

            tool = {
              editor = "nvim";
              # shell = "/bin/zsh";
              pager = "less -FIRX";
              fzf-preview = "bat -p --color always {-1}";
            };

            filter = {
              recents = "--sort created- --created-after 'last two weeks'";
            };

            alias = {
              edlast = "zk edit --limit 1 --sort modified- $@";
              recent = "zk edit --sort created- --created-after 'last two weeks' --interactive";
              lucky = "zk list --quiet --format full --sort random --limit 1";
            };

            lsp = {
              diagnostics = {
                wiki-title = "hint";
                dead-link = "error";
              };
            };
          };
        };
      };

      home.sessionVariables.ZK_NOTEBOOK_DIR = inputs.private.paths.notes;

      programs.nvf.settings.vim = mkIf cfg.zk.enable {
        extraPlugins = {
          zk-nvim = {
            package = pkgs.vimPlugins.zk-nvim;
            setup = ''
              require("zk").setup({
                -- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
                -- or select" (`vim.ui.select`).
                picker = "telescope",
                -- telescope = require("telescope.themes").get_ivy(),

                lsp = {
                  -- `config` is passed to `vim.lsp.start(config)`
                  config = {
                    name = "zk",
                    cmd = { "zk", "lsp" },
                    filetypes = { "markdown" },
                    -- on_attach = ...
                    -- etc, see `:h vim.lsp.start()`
                  },

                  -- automatically attach buffers in a zk notebook that match the given filetypes
                  auto_attach = {
                    enabled = true,
                  },
                },
              })
            '';
          };
        };
      };

      home.packages = [
      ];
    };
  }
