{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.mynix.firefox;
in
  with lib; {
    options.mynix = {
      firefox = {
        enable = mkEnableOption "Firefox with Tridactyl";
        defaultBrowser = mkEnableOption "Set Firefox as the default browser";
      };
    };

    config = mkIf cfg.enable {
      programs.firefox = {
        enable = true;

        # Use the default Firefox package
        package = pkgs.firefox;

        # Native messaging hosts for extensions
        nativeMessagingHosts = [
          pkgs.tridactyl-native
        ];

        # Firefox policies for system-wide settings
        policies = {
          # Disable telemetry
          DisableTelemetry = true;
          DisableFirefoxStudies = true;

          # Search engine configuration
          SearchEngines = {
            Add = [
              {
                Name = "Kagi";
                URLTemplate = "https://kagi.com/search?q={searchTerms}";
                Method = "GET";
                IconURL = "https://kagi.com/favicon.ico";
                Alias = "@kagi";
                Description = "Kagi Search";
              }
            ];
            Default = "Kagi";
            Remove = ["Google" "Bing" "Amazon.com" "eBay"];
          };
        };

        # Default profile configuration
        profiles.default = {
          id = 0;
          isDefault = true;

          # Extensions
          extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
            tridactyl
            tree-style-tab
            darkreader
            auto-tab-discard
            single-file
          ];

          # Hide horizontal tab bar (using Tree Style Tab for vertical tabs)
          userChrome = ''
            #TabsToolbar {
              visibility: collapse !important;
            }
          '';

          # User preferences
          settings = {
            # Enable dark theme
            "browser.theme.content-theme" = 0; # 0 = dark, 1 = light, 2 = system

            # Privacy settings
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "dom.security.https_only_mode" = true;

            # Disable pocket
            "extensions.pocket.enabled" = false;

            # Disable sponsored content
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

            # Disable password manager (using Bitwarden instead)
            "signon.rememberSignons" = false;

            # Enable userChrome.css for Tridactyl theme integration
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            # Smooth scrolling
            "general.smoothScroll" = true;

            # Use system locale
            "intl.regional_prefs.use_os_locales" = true;

            # Search engine is set via policies (Kagi)

            # Disable autofill
            "browser.formfill.enable" = false;

            # Compact density
            "browser.uidensity" = 1;

            # Wayland support
            "widget.use-xdg-desktop-portal.file-picker" = 1;

            # Block autoplay (like qutebrowser's content.autoplay = false)
            "media.autoplay.default" = 5; # 0=allow, 1=block audible, 5=block all

            # Session restore (like qutebrowser's auto_save.session = true)
            "browser.startup.page" = 3; # Restore previous session

            # Tab unloading - ensure built-in unloading is active
            "browser.tabs.unloadOnLowMemory" = true;

            # Limit content processes to reduce memory (default 8, lower = less RAM)
            # "dom.ipc.processCount" = 4;
          };

          # Tridactyl configuration
          # This creates ~/.config/tridactyl/tridactylrc
        };
      };

      # Set Firefox as default browser when enabled
      xdg.mimeApps.defaultApplications = mkIf cfg.defaultBrowser {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };

      home.sessionVariables = mkIf cfg.defaultBrowser {
        BROWSER = "firefox";
      };

      # Tridactyl configuration file
      xdg.configFile."tridactyl/tridactylrc".text = ''
        " Tridactyl configuration for vim-like Firefox navigation

        " Reset to defaults
        sanitise tridactyllocal tridactylsync

        " Use a dark theme
        colourscheme dark

        " Smooth scrolling
        set smoothscroll true

        " Prevent escapehatch from closing Tree Style Tab sidebar
        set escapehatchsidebarhack false

        " Search engine - Kagi (matching qutebrowser config)
        set searchengine https://kagi.com/search?q=%s

        " Hint characters - home row for easier typing
        set hintchars asdfghjkl

        " Quick marks for frequently visited sites
        " Use 'go<key>' to open, 'gn<key>' to open in new tab
        quickmark g https://github.com
        quickmark m https://mail.google.com
        quickmark y https://youtube.com
        quickmark r https://reddit.com

        " Key bindings
        " Use j/k for scrolling
        bind j scrollline 5
        bind k scrollline -5

        " Use J/K for tab navigation (J=next, K=prev like scrolling direction)
        bind J tabnext
        bind K tabprev

        " d to close tab, u to undo close
        bind d tabclose
        bind u undo

        " Open new tab
        bind t fillcmdline tabopen

        " Yank current URL
        bind yy clipboard yank

        " Open clipboard URL in current tab
        bind p clipboard open
        " Open clipboard URL in new tab
        bind P clipboard tabopen

        " Search in current tab
        bind / fillcmdline find
        bind n findnext 1
        bind N findnext -1

        " Go to specific tabs by number
        bind 1 tab 1
        bind 2 tab 2
        bind 3 tab 3
        bind 4 tab 4
        bind 5 tab 5
        bind 6 tab 6
        bind 7 tab 7
        bind 8 tab 8
        bind 9 tablast

        " Follow links (hint mode)
        " f for follow in current tab, F for new tab
        bind f hint
        bind F hint -t

        " Open in background tab
        bind ;b hint -b

        " Escape to normal mode from insert mode
        bind --mode=insert <Escape> composite unfocus | mode normal

        " Toggle ignore mode (Ctrl+e) - passes all keys to the page
        bind <C-e> mode ignore

        " gi to focus first input
        bind gi focusinput -l

        " Comment toggle for video sites (useful for YouTube)
        bind gc hint -c [class*=comment]

        " Disable some default bindings that conflict with website shortcuts
        unbind <C-f>

        " Tree Style Tab integration
        " T - open new tab as child of current tab
        bind T composite tabopen -b | tstattach %

        " Tree navigation - indent/outdent
        bind > js browser.runtime.sendMessage("treestyletab@piro.sakura.ne.jp", {type: "indent", tab: "current"})
        bind < js browser.runtime.sendMessage("treestyletab@piro.sakura.ne.jp", {type: "outdent", tab: "current"})

        " Tree folding (vim-style)
        bind zc js browser.runtime.sendMessage("treestyletab@piro.sakura.ne.jp", {type: "collapse-tree", tab: "current"})
        bind zo js browser.runtime.sendMessage("treestyletab@piro.sakura.ne.jp", {type: "expand-tree", tab: "current"})
        bind za js browser.runtime.sendMessage("treestyletab@piro.sakura.ne.jp", {type: "toggle-tree-collapsed", tab: "current"})

        " Toggle TST sidebar
        bind zs sidebar treestyletab_piro_sakura_ne_jp-sidebar-action

        " Site-specific settings
        " Disable Tridactyl on sites where it conflicts
        autocmd DocStart mail.google.com mode ignore
        autocmd DocStart docs.google.com mode ignore
        autocmd DocStart sheets.google.com mode ignore
        autocmd DocStart slides.google.com mode ignore

        " Editor command - use neovim in terminal
        set editorcmd kitty -e nvim
      '';

      # Remove Firefox from gui-software.nix packages since we manage it here
      # The gui-software module should be updated to not include firefox in home.packages
    };
  }
