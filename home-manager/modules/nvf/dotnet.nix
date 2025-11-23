{
  ...
}: {
  programs.nvf.settings.vim = {
    # Dotnet development commands and keybindings
    luaConfigRC.dotnet = ''
      -- MSBuild error format for quickfix integration
      -- Format: File(line,col): error CODE: Message
      vim.opt.errorformat:prepend([[%f(%l\,%c): %trror %m]])
      vim.opt.errorformat:prepend([[%f(%l\,%c): %tarning %m]])
      vim.opt.errorformat:prepend([[%f : %trror %m]])
      vim.opt.errorformat:prepend([[%f : %tarning %m]])

      -- Find the solution or project file in the current directory or parent directories
      local function find_dotnet_root()
        local cwd = vim.fn.getcwd()
        local patterns = { "*.sln", "*.csproj", "*.fsproj" }

        for _, pattern in ipairs(patterns) do
          local files = vim.fn.glob(cwd .. "/" .. pattern, false, true)
          if #files > 0 then
            return cwd, files[1]
          end
        end

        -- Search parent directories
        local parent = vim.fn.fnamemodify(cwd, ":h")
        while parent ~= cwd do
          for _, pattern in ipairs(patterns) do
            local files = vim.fn.glob(parent .. "/" .. pattern, false, true)
            if #files > 0 then
              return parent, files[1]
            end
          end
          cwd = parent
          parent = vim.fn.fnamemodify(cwd, ":h")
        end

        return vim.fn.getcwd(), nil
      end

      -- Run dotnet command in toggleterm
      local function dotnet_term(cmd, name)
        local Terminal = require("toggleterm.terminal").Terminal
        local root, _ = find_dotnet_root()

        local dotnet_cmd = Terminal:new({
          cmd = "cd " .. root .. " && " .. cmd,
          dir = root,
          direction = "float",
          float_opts = {
            border = "curved",
          },
          close_on_exit = false,
          on_open = function(term)
            vim.cmd("startinsert!")
          end,
        })
        dotnet_cmd:toggle()
      end

      -- Run dotnet build and populate quickfix
      local function dotnet_build()
        local root, project = find_dotnet_root()
        if not project then
          vim.notify("No .sln, .csproj, or .fsproj found", vim.log.levels.WARN)
          return
        end

        vim.notify("Building: " .. vim.fn.fnamemodify(project, ":t"), vim.log.levels.INFO)

        -- Run build and capture output to quickfix
        local cmd = "dotnet build " .. vim.fn.shellescape(project) .. " 2>&1"
        vim.fn.setqflist({}, "r", { title = "dotnet build" })

        vim.fn.jobstart(cmd, {
          cwd = root,
          stdout_buffered = true,
          stderr_buffered = true,
          on_stdout = function(_, data, _)
            if data then
              local lines = {}
              for _, line in ipairs(data) do
                if line ~= "" then
                  table.insert(lines, line)
                end
              end
              if #lines > 0 then
                vim.fn.setqflist({}, "a", { lines = lines })
              end
            end
          end,
          on_exit = function(_, code, _)
            vim.schedule(function()
              if code == 0 then
                vim.notify("Build succeeded!", vim.log.levels.INFO)
              else
                vim.notify("Build failed! Check quickfix (:copen)", vim.log.levels.ERROR)
                vim.cmd("copen")
              end
            end)
          end,
        })
      end

      -- Run dotnet test and show results
      local function dotnet_test()
        dotnet_term("dotnet test --logger 'console;verbosity=detailed'", "dotnet test")
      end

      -- Run dotnet test for current file (if it's a test file)
      local function dotnet_test_file()
        local file = vim.fn.expand("%:p")
        local root, _ = find_dotnet_root()

        -- Try to determine the test filter based on the filename
        local filename = vim.fn.expand("%:t:r")
        local filter = "--filter FullyQualifiedName~" .. filename

        dotnet_term("dotnet test " .. filter .. " --logger 'console;verbosity=detailed'", "dotnet test file")
      end

      -- Run dotnet run
      local function dotnet_run()
        dotnet_term("dotnet run", "dotnet run")
      end

      -- Run dotnet watch run
      local function dotnet_watch()
        dotnet_term("dotnet watch run", "dotnet watch")
      end

      -- Run dotnet clean
      local function dotnet_clean()
        local root, project = find_dotnet_root()
        if not project then
          vim.notify("No .sln, .csproj, or .fsproj found", vim.log.levels.WARN)
          return
        end

        vim.fn.jobstart("dotnet clean " .. vim.fn.shellescape(project), {
          cwd = root,
          on_exit = function(_, code, _)
            vim.schedule(function()
              if code == 0 then
                vim.notify("Clean completed!", vim.log.levels.INFO)
              else
                vim.notify("Clean failed!", vim.log.levels.ERROR)
              end
            end)
          end,
        })
      end

      -- Restore packages
      local function dotnet_restore()
        local root, project = find_dotnet_root()
        if not project then
          vim.notify("No .sln, .csproj, or .fsproj found", vim.log.levels.WARN)
          return
        end

        vim.notify("Restoring packages...", vim.log.levels.INFO)
        vim.fn.jobstart("dotnet restore " .. vim.fn.shellescape(project), {
          cwd = root,
          on_exit = function(_, code, _)
            vim.schedule(function()
              if code == 0 then
                vim.notify("Restore completed!", vim.log.levels.INFO)
              else
                vim.notify("Restore failed!", vim.log.levels.ERROR)
              end
            end)
          end,
        })
      end

      -- Create user commands
      vim.api.nvim_create_user_command("DotnetBuild", dotnet_build, { desc = "Run dotnet build" })
      vim.api.nvim_create_user_command("DotnetTest", dotnet_test, { desc = "Run dotnet test" })
      vim.api.nvim_create_user_command("DotnetTestFile", dotnet_test_file, { desc = "Run dotnet test for current file" })
      vim.api.nvim_create_user_command("DotnetRun", dotnet_run, { desc = "Run dotnet run" })
      vim.api.nvim_create_user_command("DotnetWatch", dotnet_watch, { desc = "Run dotnet watch run" })
      vim.api.nvim_create_user_command("DotnetClean", dotnet_clean, { desc = "Run dotnet clean" })
      vim.api.nvim_create_user_command("DotnetRestore", dotnet_restore, { desc = "Run dotnet restore" })

      -- Keybindings for dotnet commands
      vim.keymap.set("n", "<leader>db", dotnet_build, { desc = "Dotnet Build (quickfix)" })
      vim.keymap.set("n", "<leader>dt", dotnet_test, { desc = "Dotnet Test (terminal)" })
      vim.keymap.set("n", "<leader>dT", dotnet_test_file, { desc = "Dotnet Test current file" })
      vim.keymap.set("n", "<leader>dr", dotnet_run, { desc = "Dotnet Run (terminal)" })
      vim.keymap.set("n", "<leader>dw", dotnet_watch, { desc = "Dotnet Watch (terminal)" })
      vim.keymap.set("n", "<leader>dc", dotnet_clean, { desc = "Dotnet Clean" })
      vim.keymap.set("n", "<leader>dp", dotnet_restore, { desc = "Dotnet Restore packages" })

      -- Register which-key group if available
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<leader>d", group = "Dotnet" },
        })
      end
    '';
  };
}
