{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.nvf.settings = {
    vim = {
      # LSP Configuration (equivalent to kickstart's LSP setup)
      lsp = {
        enable = true;
        formatOnSave = true;
        lspkind.enable = true;
        lightbulb.enable = true;
        lspsaga.enable = false; # Enable if you want enhanced LSP UI
        nvim-docs-view.enable = true;

        # Trouble for diagnostics (equivalent to kickstart's trouble setup)
        trouble.enable = true;

        # LSP signature help
        lspSignature.enable = true;

        # Mappings for LSP functions
        mappings = {
          addWorkspaceFolder = "<leader>wa";
          removeWorkspaceFolder = "<leader>wr";
          listWorkspaceFolders = "<leader>wl";

          goToDeclaration = "gD";
          goToDefinition = "gd";
          # goToImplementation = "gt";
          goToType = "<leader>D";
          listReferences = "gr";

          hover = "K";
          signatureHelp = "<C-k>";

          renameSymbol = "<leader>rn";
          codeAction = "<leader>.";

          format = "<leader>lf";

          # Diagnostic mappings
          previousDiagnostic = "[d";
          nextDiagnostic = "]d";
          openDiagnosticFloat = "<leader>e";
          # gotoQuickfixList = "<leader>q";
        };
      };

      # Language-specific configurations
      languages = {
        enableTreesitter = true;
        enableFormat = true;
        enableExtraDiagnostics = true;

        # Nix support (essential for NixOS users)
        nix = {
          enable = true;
          lsp = {
            enable = true;
            server = "nixd"; # Switched from nil to nixd for better functionality
          };
          format = {
            enable = true;
            type = "alejandra"; # or "nixpkgs-fmt"
          };
          extraDiagnostics = {
            enable = true;
            types = ["statix" "deadnix"];
          };
        };

        # Lua support (for Neovim configuration)
        lua = {
          enable = true;
          lsp = {
            enable = true;
            lazydev.enable = true; # Better Neovim API support
          };
          format = {
            enable = true;
            type = "stylua";
          };
        };

        # Markdown support
        markdown = {
          enable = true;
          format = {
            enable = true;
            type = "prettierd";
          };
          lsp = {
            enable = true;
            server = "marksman";
          };
        };

        # Web development support
        html = {
          enable = true;
        };

        css = {
          enable = true;
          format = {
            enable = true;
            type = "prettier";
          };
        };

        # TypeScript/JavaScript support
        ts = {
          enable = true;
          format = {
            enable = true;
            type = "prettier";
          };
          lsp = {
            enable = true;
            server = "ts_ls";
          };
          extraDiagnostics = {
            enable = true;
            types = ["eslint_d"];
          };
        };

        # Python support
        python = {
          enable = true;
          format = {
            enable = true;
            type = "black";
          };
          lsp = {
            enable = true;
            server = "pyright";
          };
        };

        # Rust support (if needed)
        rust = {
          enable = true;
          crates.enable = false; # Disabled - triggers null_ls deprecation warning
          format.enable = true;
          lsp = {
            enable = true;
            package = ["rust_analyzer"];
          };
        };

        # Go support (if needed)
        go = {
          enable = true;
          format.enable = true;
          lsp.enable = true;
        };

        # C/C++ support (if needed)
        clang = {
          enable = true;
          # format.enable = true;
          lsp = {
            enable = true;
            server = "clangd";
          };
        };

        csharp = {
          enable = true;
          # format.enable = true;
          lsp = {
            enable = true;
            server = "csharp_ls";
          };
        };
      };

      # Treesitter configuration (equivalent to kickstart's treesitter setup)
      treesitter = {
        enable = true;
        fold = true;
        context.enable = true;

        # Additional treesitter modules
        addDefaultGrammars = true;

        # Custom grammars for languages not included by default
        grammars =
          [
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.gren
            pkgs.tree-sitter-grammars.tree-sitter-norg
            pkgs.tree-sitter-grammars.tree-sitter-norg-meta
          ]
          ++ lib.optional config.mynix.elm.enable pkgs.vimPlugins.nvim-treesitter.builtGrammars.elm;

        # Highlight, indentation, etc.
        highlight = {
          enable = true;
          additionalVimRegexHighlighting = false;
        };

        incrementalSelection = {
          enable = true;
        };

        indent = {
          enable = true;
        };
      };

      # Debugging support (DAP - Debug Adapter Protocol)
      debugger.nvim-dap = {
        enable = true;
        ui.enable = true;

        # Language-specific debug configurations will be set up automatically
        # by the language modules above when they include DAP support
      };

      # Conform for formatting
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          formatters_by_ft = {
            html = ["prettier"];
            css = ["prettier"];
            javascript = ["prettier"];
            typescript = ["prettier"];
            json = ["prettier"];
          };
          formatters = {
            prettier = {};
          };
        };
      };

      # Custom LSP configurations and file type detection
      luaConfigRC =
        {
          # File type detection for template files and Gren
          filetypeDetection = ''
            -- Detect template files as their base type
            vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
              pattern = "*.json.template",
              callback = function()
                vim.bo.filetype = "json"
              end,
            })

            vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
              pattern = "*.html.template",
              callback = function()
                vim.bo.filetype = "html"
              end,
            })

            -- Detect Gren files
            vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
              pattern = "*.gren",
              callback = function()
                vim.bo.filetype = "gren"
              end,
            })

          # JSON LSP configuration
          jsonLsp = ''
            require('lspconfig').jsonls.setup({
              cmd = { "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server", "--stdio" },
              filetypes = { "json", "jsonc" },
              settings = {
                json = {
                  validate = { enable = true },
                },
              },
            })
          '';
        }
        // lib.optionalAttrs config.mynix.elm.enable {
          # Custom Elm LSP configuration
          elmLsp = ''
            -- Custom Elm LSP configuration
            local lspconfig = require('lspconfig')

            -- Get capabilities from nvf's LSP configuration
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            lspconfig.elmls.setup({
              capabilities = capabilities,
              -- Root directory detection for elm.json
              root_dir = lspconfig.util.root_pattern("elm.json"),
              -- Let nvf handle the keymaps through LspAttach autocmd
              settings = {
                elmLS = {
                  elmPath = "${pkgs.elmPackages.elm}/bin/elm",
                  elmFormatPath = "${pkgs.elmPackages.elm-format}/bin/elm-format",
                  elmTestPath = "${pkgs.elmPackages.elm-test}/bin/elm-test",
                }
              }
            })
          '';
        };
    };
  };
}
