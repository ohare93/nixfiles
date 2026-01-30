{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.yazi;
in
  with lib; {
    options.mynix = {
      yazi = {
        enable = mkEnableOption "Yazi terminal file manager with customizations";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.yazi
        pkgs.ripdrag
        pkgs.xdg-desktop-portal-termfilechooser
      ];

      # Yazi main configuration
      xdg.configFile."yazi/yazi.toml".text = ''
        [plugin]
        prepend_preloaders = [
          { mime = "application/openxmlformats-officedocument.*", run = "office" },
          { mime = "application/oasis.opendocument.*", run = "office" },
          { mime = "application/ms-*", run = "office" },
          { mime = "application/msword", run = "office" },
          { name = "*.pptx", run = "office" },
          { name = "*.docx", run = "office" },
          { name = "*.xlsx", run = "office" },
        ]

        prepend_previewers = [
          { mime = "application/openxmlformats-officedocument.*", run = "office" },
          { mime = "application/oasis.opendocument.*", run = "office" },
          { mime = "application/ms-*", run = "office" },
          { mime = "application/msword", run = "office" },
          { name = "*.pptx", run = "office" },
          { name = "*.docx", run = "office" },
          { name = "*.xlsx", run = "office" },
        ]
      '';

      # Yazi keymap configuration
      xdg.configFile."yazi/keymap.toml".text = ''
        # Drop to shell - press ! to open $SHELL in current directory
        [[mgr.prepend_keymap]]
        on   = "!"
        run  = 'shell "''$SHELL" --block'
        desc = "Open shell here"

        # ripdrag - press D (Shift+D) for drag-and-drop
        [[mgr.prepend_keymap]]
        on   = "D"
        run  = "shell 'ripdrag \"''$@\" -x 2>/dev/null &' --confirm"
        desc = "Drag and drop with ripdrag"

        # Yank and copy to clipboard (Wayland)
        [[mgr.prepend_keymap]]
        on  = "y"
        run = [ "shell -- for path in \"''$@\"; do echo \"file://''$path\"; done | wl-copy -t text/uri-list", "yank" ]
        desc = "Yank and copy to clipboard"

        # Toggle preview pane
        [[mgr.prepend_keymap]]
        on   = "T"
        run  = "plugin toggle-pane --args=max-preview"
        desc = "Maximize or restore preview pane"

        [[mgr.prepend_keymap]]
        on   = "<A-p>"
        run  = "plugin toggle-pane --args=min-preview"
        desc = "Hide or show preview pane"
      '';

      # Yazi init.lua - status bar customization and plugin loading
      xdg.configFile."yazi/init.lua".text = ''
        -- Show user/group in status bar
        Status:children_add(function()
          local h = cx.active.current.hovered
          if not h or ya.target_family() ~= "unix" then
            return ""
          end
          return ui.Line {
            ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
            ":",
            ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
            " ",
          }
        end, 500, Status.RIGHT)

        -- Load folder-rules plugin for Downloads sorting
        require("folder-rules"):setup()
      '';

      # Folder rules plugin - sorts Downloads by modification time
      xdg.configFile."yazi/plugins/folder-rules.yazi/main.lua".text = ''
        local function setup()
          ps.sub("cd", function()
            local cwd = cx.active.current.cwd
            if cwd:ends_with("Downloads") then
              ya.emit("sort", { "mtime", reverse = true, dir_first = false })
            else
              ya.emit("sort", { "alphabetical", reverse = false, dir_first = true })
            end
          end)
        end

        return { setup = setup }
      '';

      # Toggle-pane plugin - show/hide/maximize preview pane
      xdg.configFile."yazi/plugins/toggle-pane.yazi/main.lua".text = ''
        --- @since 25.5.31
        --- @sync entry

        local function entry(st, job)
          local R = rt.mgr.ratio
          job = type(job) == "string" and { args = { job } } or job

          st.parent = st.parent or R.parent
          st.current = st.current or R.current
          st.preview = st.preview or R.preview

          local act, to = string.match(job.args[1] or "", "(.-)-(.+)")
          if act == "min" then
            st[to] = st[to] == R[to] and 0 or R[to]
          elseif act == "max" then
            local max = st[to] == 65535 and R[to] or 65535
            st.parent = st.parent == 65535 and R.parent or st.parent
            st.current = st.current == 65535 and R.current or st.current
            st.preview = st.preview == 65535 and R.preview or st.preview
            st[to] = max
          end

          if not st.old then
            st.old = Tab.layout
            Tab.layout = function(self)
              local all = st.parent + st.current + st.preview
              self._chunks = ui.Layout()
                :direction(ui.Layout.HORIZONTAL)
                :constraints({
                  ui.Constraint.Ratio(st.parent, all),
                  ui.Constraint.Ratio(st.current, all),
                  ui.Constraint.Ratio(st.preview, all),
                })
                :split(self._area)
            end
          end

          if not act then
            Tab.layout, st.old = st.old, nil
            st.parent, st.current, st.preview = nil, nil, nil
          end
          ya.emit("app:resize", {})
        end

        return { entry = entry }
      '';

      # Office document preview plugin (pptx, docx, xlsx)
      # From https://github.com/macydnah/office.yazi
      xdg.configFile."yazi/plugins/office.yazi/main.lua".text = ''
        --- @since 25.2.7

        local M = {}

        function M:peek(job)
          local start, cache = os.clock(), ya.file_cache(job)
          if not cache then
            return
          end

          local ok, err = self:preload(job)
          if not ok or err then
            return
          end

          ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))
          ya.image_show(cache, job.area)
          ya.preview_widgets(job, {})
        end

        function M:seek(job)
          local h = cx.active.current.hovered
          if h and h.url == job.file.url then
            local step = ya.clamp(-1, job.units, 1)
            ya.manager_emit("peek", { math.max(0, cx.active.preview.skip + step), only_if = job.file.url })
          end
        end

        function M:doc2pdf(job)
          local tmp = "/tmp/yazi-" .. ya.uid() .. "/" .. ya.hash("office.yazi") .. "/"

          local libreoffice = Command("libreoffice")
            :arg({
              "--headless",
              "--convert-to",
              'pdf:draw_pdf_Export:{"PageRange":{"type":"string","value":"' .. job.skip + 1 .. '"}}',
              "--outdir",
              tmp,
              tostring(job.file.url),
            })
            :stdin(Command.NULL)
            :stdout(Command.PIPED)
            :stderr(Command.PIPED)
            :output()

          if not libreoffice.status.success then
            local output = libreoffice.stdout .. libreoffice.stderr
            local version = (output:match("LibreOffice .+") or ""):gsub("%\n.*", "")
            local error = (output:match("Error:? .+") or ""):gsub("%\n.*", "")
            if version ~= "" or error ~= "" then
              ya.err((version or "LibreOffice") .. " " .. (error or "Unknown error"))
            end
            return nil, "Failed to preconvert to PDF"
          end

          local tmp = tmp .. job.file.name:gsub("%.[^%.]+$", ".pdf")
          local read_permission = io.open(tmp, "r")
          if not read_permission then
            return nil, "Failed to read PDF"
          end
          read_permission:close()

          return tmp
        end

        function M:preload(job)
          local cache = ya.file_cache(job)
          if not cache or fs.cha(cache) then
            return true
          end

          local tmp_pdf, err = self:doc2pdf(job)
          if not tmp_pdf then
            return true, err
          end

          local output, err = Command("pdftoppm")
            :arg({
              "-singlefile",
              "-jpeg",
              "-jpegopt",
              "quality=" .. rt.preview.image_quality,
              "-f",
              1,
              tostring(tmp_pdf),
            })
            :stdout(Command.PIPED)
            :stderr(Command.PIPED)
            :output()

          local rm_tmp_pdf, rm_err = fs.remove("file", Url(tmp_pdf))
          if not rm_tmp_pdf then
            ya.err("Failed to remove " .. tmp_pdf)
          end

          if not output then
            return true, "Failed to start pdftoppm"
          elseif not output.status.success then
            local pages = tonumber(output.stderr:match("the last page %((%d+)%)")) or 0
            if job.skip > 0 and pages > 0 then
              ya.mgr_emit("peek", { math.max(0, pages - 1), only_if = job.file.url, upper_bound = true })
            end
            return true, "Failed to convert PDF to image"
          end

          return fs.write(cache, output.stdout)
        end

        return M
      '';

      # xdg-desktop-portal-termfilechooser configuration
      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=yazi-wrapper.sh
        default_dir=''$HOME
        env=TERMCMD=kitty
      '';

      # XDG portal preference - use termfilechooser for file dialogs
      xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
        [preferred]
        org.freedesktop.impl.portal.FileChooser=termfilechooser
      '';

      # Yazi wrapper script for xdg-desktop-portal-termfilechooser
      home.file.".local/bin/yazi-wrapper.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # Wrapper script for xdg-desktop-portal-termfilechooser
          # Arguments: $1 = action (open/save), $2 = output file, $3+ = starting path

          action="''$1"
          output_file="''$2"
          shift 2

          if [[ "''$action" == "save" ]]; then
            # For save dialogs, yazi needs --chooser-file
            ''$TERMCMD -e yazi --chooser-file="''$output_file" "''$@"
          else
            # For open dialogs
            ''$TERMCMD -e yazi --chooser-file="''$output_file" "''$@"
          fi
        '';
      };
    };
  }
