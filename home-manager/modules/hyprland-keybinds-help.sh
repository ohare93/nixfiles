#!/usr/bin/env bash

# Hyprland Keybindings Help Script
# Shows a rofi menu with all important keybindings

keybindings="
🚀 APPLICATIONS
Super + Return               Terminal (Foot)
Super + B                   Browser (Qutebrowser)
Super + D                   Application Launcher

🪟 WINDOW MANAGEMENT
Super + W                   Close Window
Super + V                   Toggle Floating
Super + F                   Toggle Fullscreen
Super + J                   Toggle Split Direction
Super + P                   Pseudo Tiling

🧭 NAVIGATION
Super + ←/→/↑/↓             Move Focus (Arrow Keys)
Super + H/J/K/L             Move Focus (Vim Keys)

📋 WORKSPACES
Super + 1-9,0               Switch to Workspace
Super + Shift + 1-9,0       Move Window to Workspace
Super + S                   Toggle Scratchpad
Super + Shift + S           Move to Scratchpad

🔧 WINDOW MANIPULATION
Super + Ctrl + H/J/K/L      Resize Window
Super + Shift + H/J/K/L     Move Window
Super + Mouse Drag          Move Window
Super + Right Click         Resize Window

📸 SYSTEM
Print                       Screenshot Full Screen → /tmp/screenshots + clipboard
Super + Print               Screenshot Region → /tmp/screenshots + clipboard
Super + Shift + Print       Screenshot Window → /tmp/screenshots + clipboard
Super + Alt + Print         Screenshot Region → copy FILE PATH to clipboard (for chat)
Super + Shift + Q           Exit Hyprland
Super + Shift + R           Reload Config
Super + -                   Show This Help

🔊 MEDIA (Function Keys)
F1-F12 + Fn                Audio/Brightness Controls
"

# Show in rofi
echo "$keybindings" | rofi -dmenu -i -p "Hyprland Keybindings" \
    -theme-str 'window {width: 50%; height: 70%;}' \
    -theme-str 'listview {lines: 25;}' \
    -show-icons