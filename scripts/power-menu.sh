#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
choice=$(printf 'Lock\nLogout\nReboot\nShutdown\nScreenshot' \
    | wofi --dmenu --prompt 'Power: ' --style "$PROJECT_DIR/configs/wofi/style.css")

case "$choice" in
    Lock)       swaylock -f -c 000000 ;;
    Logout)     swaymsg exit ;;
    Reboot)     systemctl reboot ;;
    Shutdown)   systemctl poweroff ;;
    Screenshot) flameshot full -c -p ~/Pictures ;;
esac
