#!/usr/bin/env bash
choice=$(printf 'Lock\nLogout\nReboot\nShutdown\nScreenshot' \
    | wofi --dmenu --prompt 'Power: ' --style ~/Projects/OdysseyWM/configs/wofi/style.css)

case "$choice" in
    Lock)       swaylock -f -c 000000 ;;
    Logout)     swaymsg exit ;;
    Reboot)     systemctl reboot ;;
    Shutdown)   systemctl poweroff ;;
    Screenshot) flameshot full -c -p ~/Pictures ;;
esac
