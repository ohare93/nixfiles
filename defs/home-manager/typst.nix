{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.typst;
in
  with lib; {
    options.mynix.typst = {
      enable = mkEnableOption "typst document authoring";
    };

    config = mkIf cfg.enable {
      # Install typst globally
      home.packages = [pkgs.typst];

      # nvf Typst language support
      programs.nvf.settings.vim = {
        languages.typst = {
          enable = true;
          lsp.enable = true; # tinymist
          treesitter.enable = true;
          format.enable = true; # typstyle
        };

        # Custom commands and keybindings
        luaConfigRC.typst = ''
          -- Typst helper functions
          local function get_typst_pdf_path()
            local file = vim.fn.expand("%:p")
            if file:match("%.typ$") then
              return file:gsub("%.typ$", ".pdf")
            end
            return nil
          end

          local function typst_open_pdf()
            local pdf_path = get_typst_pdf_path()
            if not pdf_path then
              vim.notify("Not a Typst file", vim.log.levels.WARN)
              return
            end
            if vim.fn.filereadable(pdf_path) == 0 then
              vim.notify("PDF not found. Run compile first.", vim.log.levels.WARN)
              return
            end
            vim.fn.jobstart({"zathura", pdf_path}, {detach = true})
          end

          local function typst_compile()
            local file = vim.fn.expand("%:p")
            if not file:match("%.typ$") then
              vim.notify("Not a Typst file", vim.log.levels.WARN)
              return
            end
            vim.notify("Compiling...", vim.log.levels.INFO)
            vim.fn.jobstart({"typst", "compile", file}, {
              on_exit = function(_, code, _)
                vim.schedule(function()
                  if code == 0 then
                    vim.notify("Compiled!", vim.log.levels.INFO)
                  else
                    vim.notify("Compilation failed!", vim.log.levels.ERROR)
                  end
                end)
              end,
            })
          end

          local function typst_watch()
            local file = vim.fn.expand("%:p")
            if not file:match("%.typ$") then
              vim.notify("Not a Typst file", vim.log.levels.WARN)
              return
            end
            local ok, toggleterm = pcall(require, "toggleterm.terminal")
            if not ok then
              vim.notify("toggleterm not available", vim.log.levels.ERROR)
              return
            end
            local Terminal = toggleterm.Terminal
            local watch = Terminal:new({
              cmd = "typst watch " .. vim.fn.shellescape(file),
              dir = vim.fn.expand("%:p:h"),
              direction = "float",
              close_on_exit = false,
            })
            watch:toggle()
          end

          -- Commands
          vim.api.nvim_create_user_command("TypstCompile", typst_compile, {})
          vim.api.nvim_create_user_command("TypstWatch", typst_watch, {})
          vim.api.nvim_create_user_command("TypstOpenPdf", typst_open_pdf, {})

          -- Keybindings (Typst files only)
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "typst",
            callback = function()
              local opts = { buffer = true, silent = true }
              vim.keymap.set("n", "<leader>tc", typst_compile,
                vim.tbl_extend("force", opts, { desc = "Typst Compile" }))
              vim.keymap.set("n", "<leader>tw", typst_watch,
                vim.tbl_extend("force", opts, { desc = "Typst Watch" }))
              vim.keymap.set("n", "<leader>tp", typst_open_pdf,
                vim.tbl_extend("force", opts, { desc = "Typst open PDF" }))

              local ok, wk = pcall(require, "which-key")
              if ok then
                wk.add({ { "<leader>t", group = "Typst", buffer = 0 } })
              end
            end,
          })
        '';
      };
    };
  }
