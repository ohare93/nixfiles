{
  lib,
  config,
  ...
}:
let
  cfg = config.mynix.kitty;
in
with lib; {
  options.mynix.kitty = {
    enable = mkEnableOption "Kitty terminal with customizations";
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      # JetBrains Mono Nerd Font - matches system fonts
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 12;
      };

      # Shell integration for zsh
      shellIntegration = {
        mode = "enabled";
        enableZshIntegration = true;
      };

      settings = {
        # Performance (GPU-accelerated)
        sync_to_monitor = true;
        repaint_delay = 10;
        input_delay = 3;

        # Scrollback
        scrollback_lines = 10000;
        scrollback_pager_history_size = 100;

        # Mouse
        copy_on_select = "clipboard";
        mouse_hide_wait = 3;
        url_style = "curly";
        open_url_with = "default";
        detect_urls = true;

        # Bell
        enable_audio_bell = false;
        visual_bell_duration = 0;

        # Window
        remember_window_size = true;
        initial_window_width = 120;
        initial_window_height = 35;
        window_padding_width = 8;
        placement_strategy = "center";
        hide_window_decorations = false;
        confirm_os_window_close = -1;

        # Cursor (block for vi-mode feel)
        cursor_shape = "block";
        cursor_blink_interval = 0;

        # Tab bar
        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_bar_min_tabs = 2;

        # Misc
        allow_remote_control = "socket-only";
        listen_on = "unix:/tmp/kitty";
        shell_integration = "enabled";
      }
      // optionalAttrs (config.mynix.terminal-misc.zellij.enable or false) {
        shell = "zellij --layout minimal";
      };

      # Keybindings (keyboard-centric)
      keybindings = {
        # Scrollback
        "ctrl+shift+k" = "scroll_line_up";
        "ctrl+shift+j" = "scroll_line_down";
        "ctrl+shift+page_up" = "scroll_page_up";
        "ctrl+shift+page_down" = "scroll_page_down";
        "ctrl+shift+home" = "scroll_home";
        "ctrl+shift+end" = "scroll_end";

        # Tabs
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+q" = "close_tab";
        "ctrl+shift+right" = "next_tab";
        "ctrl+shift+left" = "previous_tab";
        "ctrl+shift+." = "move_tab_forward";
        "ctrl+shift+," = "move_tab_backward";

        # Windows/Splits
        "ctrl+shift+enter" = "new_window";
        "ctrl+shift+w" = "close_window";
        "ctrl+shift+]" = "next_window";
        "ctrl+shift+[" = "previous_window";

        # Font size
        "ctrl+shift+equal" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
        "ctrl+shift+0" = "change_font_size all 0";

        # Misc
        "ctrl+shift+f5" = "load_config_file";
        "ctrl+shift+u" = "kitten unicode_input";
        "ctrl+shift+e" = "open_url_with_hints";
      };
    };
  };
}
