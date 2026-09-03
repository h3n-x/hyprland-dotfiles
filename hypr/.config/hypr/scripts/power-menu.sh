#!/bin/bash

# Menu de energia via rofi: bloquear, suspender, cerrar sesion, reiniciar,
# apagar. Reiniciar/apagar piden confirmacion (accion destructiva, dificil
# de deshacer); el resto no, mismo criterio que el bind SUPER+SHIFT+M
# (salida forzada de Hyprland sin confirmar).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOCK=" Bloquear"
SUSPEND=" Suspender"
LOGOUT=" Cerrar sesion"
REBOOT=" Reiniciar"
POWEROFF=" Apagar"

selected=$(printf '%s\n%s\n%s\n%s\n%s\n' "$LOCK" "$SUSPEND" "$LOGOUT" "$REBOOT" "$POWEROFF" |
  rofi -dmenu -i -p "Energia" -theme-str 'window {width: 20%;} listview {lines: 5;}')

confirm() {
  local choice
  choice=$(printf 'No\nSi\n' | rofi -dmenu -i -p "$1" -theme-str 'window {width: 15%;} listview {lines: 2;}')
  [ "$choice" = "Si" ]
}

case "$selected" in
  "$LOCK")     exec "$SCRIPT_DIR/lock.sh" ;;
  "$SUSPEND")  exec systemctl suspend ;;
  "$LOGOUT")   exec hyprshutdown ;;
  "$REBOOT")   confirm "¿Reiniciar?" && exec systemctl reboot ;;
  "$POWEROFF") confirm "¿Apagar?" && exec systemctl poweroff ;;
  *) exit 0 ;;
esac
