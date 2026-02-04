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
        pkgs.udisks # for mount.yazi plugin (udisksctl)
        pkgs.util-linux # for mount.yazi plugin (lsblk, eject)
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

        # Mount manager - mount/unmount/eject disks
        [[mgr.prepend_keymap]]
        on   = "M"
        run  = "plugin mount"
        desc = "Open mount manager"
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

      # Mount manager plugin - mount/unmount/eject disks
      # From https://github.com/yazi-rs/plugins/tree/main/mount.yazi
      xdg.configFile."yazi/plugins/mount.yazi/main.lua".text = ''
        --- @since 25.12.29

        local toggle_ui = ya.sync(function(self)
          if self.children then
            Modal:children_remove(self.children)
            self.children = nil
          else
            self.children = Modal:children_add(self, 10)
          end
          ui.render()
        end)

        local subscribe = ya.sync(function(self)
          ps.unsub("mount")
          ps.sub("mount", function() ya.emit("plugin", { self._id, "refresh" }) end)
        end)

        local update_partitions = ya.sync(function(self, partitions)
          self.partitions = partitions
          self.cursor = math.max(0, math.min(self.cursor or 0, #self.partitions - 1))
          ui.render()
        end)

        local active_partition = ya.sync(function(self) return self.partitions[self.cursor + 1] end)

        local update_cursor = ya.sync(function(self, cursor)
          if #self.partitions == 0 then
            self.cursor = 0
          else
            self.cursor = ya.clamp(0, self.cursor + cursor, #self.partitions - 1)
          end
          ui.render()
        end)

        local M = {
          keys = {
            { on = "q", run = "quit" },
            { on = "<Esc>", run = "quit" },
            { on = "<Enter>", run = { "enter", "quit" } },

            { on = "k", run = "up" },
            { on = "j", run = "down" },
            { on = "l", run = { "enter", "quit" } },

            { on = "<Up>", run = "up" },
            { on = "<Down>", run = "down" },
            { on = "<Right>", run = { "enter", "quit" } },

            { on = "m", run = "mount" },
            { on = "u", run = "unmount" },
            { on = "e", run = "eject" },
          },
        }

        function M:new(area)
          self:layout(area)
          return self
        end

        function M:layout(area)
          local chunks = ui.Layout()
            :constraints({
              ui.Constraint.Percentage(10),
              ui.Constraint.Percentage(80),
              ui.Constraint.Percentage(10),
            })
            :split(area)

          local chunks = ui.Layout()
            :direction(ui.Layout.HORIZONTAL)
            :constraints({
              ui.Constraint.Percentage(10),
              ui.Constraint.Percentage(80),
              ui.Constraint.Percentage(10),
            })
            :split(chunks[2])

          self._area = chunks[2]
        end

        function M:entry(job)
          if job.args[1] == "refresh" then
            return update_partitions(self.obtain())
          end

          toggle_ui()
          update_partitions(self.obtain())
          subscribe()

          local tx1, rx1 = ya.chan("mpsc")
          local tx2, rx2 = ya.chan("mpsc")
          function producer()
            while true do
              local cand = self.keys[ya.which { cands = self.keys, silent = true }] or { run = {} }
              for _, r in ipairs(type(cand.run) == "table" and cand.run or { cand.run }) do
                tx1:send(r)
                if r == "quit" then
                  toggle_ui()
                  return
                end
              end
            end
          end

          function consumer1()
            repeat
              local run = rx1:recv()
              if run == "quit" then
                tx2:send(run)
                break
              elseif run == "up" then
                update_cursor(-1)
              elseif run == "down" then
                update_cursor(1)
              elseif run == "enter" then
                local active = active_partition()
                if active and active.dist then
                  ya.emit("cd", { active.dist })
                end
              else
                tx2:send(run)
              end
            until not run
          end

          function consumer2()
            repeat
              local run = rx2:recv()
              if run == "quit" then
                break
              elseif run == "mount" then
                require(".cross").operate("mount", active_partition())
              elseif run == "unmount" then
                require(".cross").operate("unmount", active_partition())
              elseif run == "eject" then
                require(".cross").operate("eject", active_partition())
              end
            until not run
          end

          ya.join(producer, consumer1, consumer2)
        end

        function M:reflow() return { self } end

        function M:redraw()
          local rows = {}
          for _, p in ipairs(self.partitions or {}) do
            if not p.sub then
              rows[#rows + 1] = ui.Row { p.main }
            elseif p.sub == "" then
              rows[#rows + 1] = ui.Row { p.main, p.label or "", p.dist or "", p.fstype or "" }
            else
              rows[#rows + 1] = ui.Row { "  " .. p.sub, p.label or "", p.dist or "", p.fstype or "" }
            end
          end

          return {
            ui.Clear(self._area),
            ui.Border(ui.Edge.ALL)
              :area(self._area)
              :type(ui.Border.ROUNDED)
              :style(ui.Style():fg("blue"))
              :title(ui.Line("Mount"):align(ui.Align.CENTER)),
            ui.Table(rows)
              :area(self._area:pad(ui.Pad(1, 2, 1, 2)))
              :header(ui.Row({ "Src", "Label", "Dist", "FSType" }):style(ui.Style():bold()))
              :row(self.cursor)
              :row_style(ui.Style():fg("blue"):underline())
              :widths {
                ui.Constraint.Length(20),
                ui.Constraint.Length(20),
                ui.Constraint.Percentage(70),
                ui.Constraint.Length(10),
              },
          }
        end

        function M.obtain()
          local tbl = {}
          local last
          for _, p in ipairs(fs.partitions()) do
            local main, sub = M.split(p.src)
            if main and last ~= main then
              if p.src == main then
                last, p.main, p.sub, tbl[#tbl + 1] = p.src, p.src, "", p
              else
                last, tbl[#tbl + 1] = main, { src = main, main = main, sub = "" }
              end
            end
            if sub then
              if tbl[#tbl].sub == "" and tbl[#tbl].main == main then
                tbl[#tbl].sub = nil
              end
              p.main, p.sub, tbl[#tbl + 1] = main, sub, p
            end
          end
          table.sort(M.fillin(tbl), function(a, b)
            if a.main == b.main then
              return (a.sub or "") < (b.sub or "")
            else
              return a.main > b.main
            end
          end)
          return tbl
        end

        function M.split(src)
          local pats = {
            { "^/dev/sd[a-z]", "%d+$" }, -- /dev/sda1
            { "^/dev/nvme%d+n%d+", "p%d+$" }, -- /dev/nvme0n1p1
            { "^/dev/mmcblk%d+", "p%d+$" }, -- /dev/mmcblk0p1
            { "^/dev/disk%d+", ".+$" }, -- /dev/disk1s1
            { "^/dev/sr%d+", ".+$" }, -- /dev/sr0
          }
          for _, p in ipairs(pats) do
            local main = src:match(p[1])
            if main then
              return main, src:sub(#main + 1):match(p[2])
            end
          end
        end

        function M.fillin(tbl)
          if ya.target_os() ~= "linux" then
            return tbl
          end

          local sources, indices = {}, {}
          for i, p in ipairs(tbl) do
            if p.sub and not p.fstype then
              sources[#sources + 1], indices[p.src] = p.src, i
            end
          end
          if #sources == 0 then
            return tbl
          end

          local output, err = Command("lsblk"):arg({ "-p", "-o", "name,fstype", "-J" }):arg(sources):output()
          if err then
            ya.dbg("Failed to fetch filesystem types for unmounted partitions: " .. err)
            return tbl
          end

          local t = ya.json_decode(output and output.stdout or "")
          for _, p in ipairs(t and t.blockdevices or {}) do
            tbl[indices[p.name]].fstype = p.fstype
          end
          return tbl
        end

        function M:click() end

        function M:scroll() end

        function M:touch() end

        return M
      '';

      xdg.configFile."yazi/plugins/mount.yazi/cross.lua".text = ''
        local M = {}

        --- @param type "mount"|"unmount"|"eject"
        --- @param partition table
        function M.operate(type, partition)
          if not partition then
            return
          elseif not partition.sub then
            return -- TODO: mount/unmount main disk
          end

          local cmd, output, err
          if ya.target_os() == "macos" then
            cmd, output, err = "diskutil", M.diskutil(type, partition.src)
          elseif ya.target_os() == "linux" then
            if type == "eject" and partition.src:match("^/dev/sr%d+") then
              M.udisksctl("unmount", partition.src)
              cmd, output, err = "eject", M.eject(partition.src)
            elseif type == "eject" then
              M.udisksctl("unmount", partition.src)
              cmd, output, err = "udisksctl", M.udisksctl("power-off", partition.src)
            else
              cmd, output, err = "udisksctl", M.udisksctl(type, partition.src)
            end
          end

          if not cmd then
            M.fail("mount.yazi is not currently supported on your platform")
          elseif not output then
            M.fail("Failed to spawn `%s`: %s", cmd, err)
          elseif not output.status.success then
            M.fail("Failed to %s `%s`: %s", type, partition.src, output.stderr)
          end
        end

        --- @param type "mount"|"unmount"|"eject"
        --- @param src string
        --- @return Output? output
        --- @return Error? err
        function M.diskutil(type, src) return Command("diskutil"):arg({ type, src }):output() end

        --- @param type "mount"|"unmount"|"power-off"
        --- @param src string
        --- @return Output? output
        --- @return Error? err
        function M.udisksctl(type, src)
          local args = { type, "-b", src, "--no-user-interaction" }
          local output, err = Command("udisksctl"):arg(args):output()

          if not output or err then
            return nil, err
          elseif output.stderr:find("org.freedesktop.UDisks2.Error.NotAuthorizedCanObtain", 1, true) then
            return require(".sudo").run_with_sudo("udisksctl", args)
          else
            return output
          end
        end

        --- @param src string
        --- @return Output? output
        --- @return Error? err
        function M.eject(src) return Command("eject"):arg({ "--traytoggle", src }):output() end

        function M.fail(...) ya.notify { title = "Mount", content = string.format(...), timeout = 10, level = "error" } end

        return M
      '';

      xdg.configFile."yazi/plugins/mount.yazi/sudo.lua".text = ''
        local M = {}

        --- Verify if `sudo` is already authenticated
        --- @return boolean
        --- @return Error?
        function M.sudo_already()
          local status, err = Command("sudo"):arg({ "--validate", "--non-interactive" }):status()
          return status and status.success or false, err
        end

        --- Run a program with `sudo` privilege
        --- @param program string
        --- @param args table
        --- @return Output? output
        --- @return Error? err
        function M.run_with_sudo(program, args)
          local cmd = Command("sudo")
            :arg({ "--stdin", "--user", "#" .. ya.uid(), "--", program })
            :arg(args)
            :stdin(Command.PIPED)
            :stdout(Command.PIPED)
            :stderr(Command.PIPED)

          if M.sudo_already() then
            return cmd:output()
          end

          local value, event = ya.input {
            pos = { "top-center", y = 3, w = 40 },
            title = string.format("Password for `sudo %s`:", program),
            obscure = true,
          }
          if not value or event ~= 1 then
            return nil, Err("Sudo password input cancelled")
          end

          local child, err = cmd:spawn()
          if not child or err then
            return nil, err
          end

          child:write_all(value .. "\n")
          child:flush()
          local output, err = child:wait_with_output()
          if not output or err then
            return nil, err
          elseif output.status.success or M.sudo_already() then
            return output
          else
            return nil, Err("Incorrect sudo password")
          end
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
