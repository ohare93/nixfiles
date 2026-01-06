{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.qutebrowser;

  # Dependencies for qute-karakeep userscript
  karakeepDeps = with pkgs; [
    single-file-cli
    curl
    coreutils # for mktemp
  ];
in
  with lib; {
    options.mynix = {
      qutebrowser = {
        enable = mkEnableOption "Qutebrowser with custom configuration";
      };
    };

    config = mkIf cfg.enable {
      programs.qutebrowser = {
        enable = true;

        # All aliases are defined in extraConfig to avoid conflicts

        # Custom keybindings from config.py
        keyBindings = {
          normal = {
            "wtt" = "write-to-tech";
            "wka" = "karakeep"; # Archive current page to Karakeep
            "wkh" = "Karakeep"; # Archive hinted link to Karakeep
          };
        };

        # Settings from config.py - only simple ones that work with Home Manager
        settings = {
          auto_save.session = true;
          colors.webpage.darkmode.enabled = true;
          content.autoplay = false;
          editor.command = ["konsole" "-e" "nvim" "{file}"];
          tabs.position = "left";
          content.local_content_can_access_remote_urls = true;
        };

        # Note: quickmarks are left in the existing ~/.config/qutebrowser/quickmarks file

        # Extra config for complex Python configurations
        extraConfig = ''
          # Don't load autoconfig to avoid conflicts with Home Manager settings
          # config.load_autoconfig(True)

          # All aliases - both simple and complex
          c.aliases = {
              "write-to-tech": "spawn zsh -c 'cd ~/Notes/logseq_dc && echo \"- {url}\" >> `zk getmonthly`'",
              "zotero": "spawn --userscript qute-zotero",
              "Zotero": "hint links userscript qute-zotero",
              "karakeep": "spawn --userscript qute-karakeep",
              "Karakeep": "hint links userscript qute-karakeep"
          }

          # Search engines setting
          c.url.searchengines = {
              "DEFAULT": "https://kagi.com/search?q={}"
          }

          # Qt chromium setting
          c.qt.chromium.experimental_web_platform_features = "never"

          # Site-specific settings can be added here if needed

          # Content security policy exclusions for userscripts
          c.content.javascript.log_message.excludes = {
              "userscript:_qute_stylesheet": [
                  "*Refused to apply inline style because it violates the following Content Security Policy directive: *"
              ],
              "userscript:_qute_js": ["*TrustedHTML*"],
          }
        '';
      };

      # Install qute-zotero userscript with proper Python environment
      home.file.".local/share/qutebrowser/userscripts/qute-zotero" = {
        source = pkgs.writeShellScript "qute-zotero" ''
          #!/usr/bin/env bash
          export PATH="${pkgs.python3.withPackages (ps: with ps; [requests])}/bin:$PATH"
          exec python3 ${./qute-zotero} "$@"
        '';
        executable = true;
      };

      # Install qute-karakeep userscript for archiving to Karakeep via SingleFile
      home.file.".local/share/qutebrowser/userscripts/qute-karakeep" = {
        source = pkgs.writeShellScript "qute-karakeep" ''
          #!/usr/bin/env bash
          export PATH="${lib.makeBinPath karakeepDeps}:$PATH"
          exec bash ${./qute-karakeep} "$@"
        '';
        executable = true;
      };
    };
  }
