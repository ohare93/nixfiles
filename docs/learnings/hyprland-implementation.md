## Hyprland Configuration Learnings

### Common Configuration Errors and Fixes

**Hyprland Version Compatibility:**

- Always check Hyprland version with `hyprland -v` before debugging
- Validate configuration with `hyprland --config ~/.config/hypr/hyprland.conf --verify-config`
- Configuration syntax changes between versions - refer to official wiki

**Deprecated Options in Hyprland 0.50.1:**

1. **Shadow Configuration** - Must use nested format:

```nix
# OLD (deprecated):
decoration = {
 drop_shadow = true;
 shadow_range = 4;
 shadow_render_power = 3;
 "col.shadow" = "rgba(1a1a1aee)";
};

# NEW (correct):
decoration = {
 shadow = {
   enabled = true;
   range = 4;
   render_power = 3;
   color = "rgba(1a1a1aee)";
 };
};
```

2. **Master Layout Options:**

- `master.new_is_master` no longer exists - remove entirely
- Most users should use `dwindle` layout instead

3. **Window Rules Syntax:**

```nix
# OLD (causes "Invalid rulev2 syntax" errors):
windowrule = [
 "float, ^(pavucontrol)$"
];

# NEW (correct):
windowrule = [
 "float, class:^pavucontrol$"
];
```

**Terminal Application Issues:**

- Always ensure terminal emulator is installed in `home.packages`
- Prefer Wayland-native terminals: `foot`, `alacritty`, `kitty`
- Konsole requires KDE dependencies - avoid for minimal Wayland setups

**Keyboard Layout Considerations:**

- Set `kb_layout = "gb"` for UK/Danish keyboards (not "us")
- When using Kanata remapping, Hyprland still needs correct physical layout
- Keybinding symbols (like `/`) depend on physical keyboard layout

**Essential Startup Services:**

- Always include in `exec-once`:
- `nm-applet --indicator` (for network/WiFi)
- `blueman-applet` (for Bluetooth)
- `waybar` (status bar)
- Missing network applet = no WiFi control in Wayland

**Debugging Hyprland Issues:**

1. Check configuration errors: `hyprland --verify-config`
2. Look for logs in `$XDG_RUNTIME_DIR/hypr/`
3. Use `journalctl --user -b 0 | grep -i hyprland` for session errors
4. Error messages appear at top of screen on startup - fix immediately

## External Configuration Files in Nix

**Critical Rule**: External config files MUST be committed to git/jj before Nix can access them.

**Proper File Inclusion Pattern**:

```nix
# CORRECT: Use relative paths from the .nix file location
xdg.configFile."app/config.ext".source = ../config/file.ext;

# WRONG: Absolute paths break Nix reproducibility
xdg.configFile."app/config.ext".source = /home/user/nixfiles/config/file.ext;
```
