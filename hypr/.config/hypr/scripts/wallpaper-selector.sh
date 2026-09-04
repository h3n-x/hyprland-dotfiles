#!/bin/bash

# Selector de wallpaper via rofi: aplica el fondo con hyprpaper (IPC) y
# regenera la paleta de colores de todo el rice con matugen.

set -euo pipefail

WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Wallpaper" "$1" -i "${2:-image-x-generic}" -t 2500
}

# -show-icons + entradas "texto\0icon\x1f/ruta" (protocolo dmenu de rofi):
# usa la imagen completa como icono, asi el selector muestra miniaturas en
# vez de una lista de nombres de archivo.
selected=$(find "$WALLPAPERS_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -printf "%f\n" 2>/dev/null |
  sort |
  while IFS= read -r name; do
    printf '%s\0icon\x1f%s\n' "$name" "$WALLPAPERS_DIR/$name"
  done | rofi -dmenu -i -show-icons -p "Wallpaper" \
    -theme-str 'element-icon { size: 160px; } listview { columns: 3; lines: 3; } window { width: 55%; }')

[ -z "$selected" ] && exit 0

wallpaper="$WALLPAPERS_DIR/$selected"
[ -f "$wallpaper" ] || { notify "No se encontro $selected" "dialog-error"; exit 1; }

# hyprpaper 0.8.x solo expone "wallpaper" y "listactive" por IPC -- ya no hay
# "preload"/"unload"/"listloaded" (devuelven "invalid hyprpaper request").
hyprctl hyprpaper wallpaper ",$wallpaper" >/dev/null

# Persiste la eleccion para que sobreviva a un reinicio de Hyprland/sesion
# (el comando de arriba solo cambia el wallpaper en vivo via IPC, hyprpaper.conf
# hace `source` de este archivo al arrancar -- ver hyprpaper.conf).
cat > ~/.config/hypr/current-wallpaper.conf <<EOF
wallpaper {
    monitor =
    path = $wallpaper
    fit_mode = cover
}
EOF

if command -v matugen >/dev/null 2>&1; then
  # --prefer evita el prompt interactivo de seleccion de color (no hay
  # terminal cuando esto corre desde un keybind)
  matugen image "$wallpaper" --prefer saturation >/dev/null 2>&1 &
fi

# ~/.face es la imagen "de usuario" que hyprlock.conf dibuja arriba del
# reloj de palabras (widget `image`, ver hypr/.config/hypr/hyprlock.conf).
# En vez de pedir una foto real, se genera un recorte cuadrado centrado del
# wallpaper elegido -- asi el "avatar" del lockscreen cambia junto con el
# resto del theming. Pisa cualquier ~/.face anterior a proposito.
if command -v magick >/dev/null 2>&1; then
  magick "$wallpaper" -gravity center -resize 512x512^ -extent 512x512 ~/.face >/dev/null 2>&1 &
fi

notify "Aplicando: $selected"
