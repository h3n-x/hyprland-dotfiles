#!/bin/bash
# Symlinkea user.js y chrome/{userChrome,userContent}.css al perfil REAL de
# LibreWolf. El nombre de la carpeta del perfil lleva un salt
# random por instalacion (ej. h86gkyyd.default-default), asi que stow no
# puede apuntarle directo con una ruta fija -- por eso este script en vez de
# un paquete stow normal. Correr una vez despues de instalar LibreWolf (o de
# nuevo si se resetea/recrea el perfil). Idempotente.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBREWOLF_DIR="$HOME/.config/librewolf/librewolf"
INI="$LIBREWOLF_DIR/profiles.ini"

[ -f "$INI" ] || {
  echo "No se encontro $INI -- corre LibreWolf al menos una vez primero." >&2
  exit 1
}

# El perfil del bloque [InstallXXXX] activo es mas confiable que [ProfileN]
# Default=1 (puede haber varios perfiles legacy con ese flag).
profile=$(awk -F= '/^\[Install/{install=1} install && /^Default=/{print $2; exit}' "$INI")
[ -n "$profile" ] || {
  echo "No se pudo determinar el perfil default en $INI" >&2
  exit 1
}

profile_dir="$LIBREWOLF_DIR/$profile"
[ -d "$profile_dir" ] || {
  echo "No existe $profile_dir" >&2
  exit 1
}

mkdir -p "$profile_dir/chrome"

ln -sf "$REPO_DIR/user.js" "$profile_dir/user.js"
# userChrome.css/userContent.css son generados enteros por matugen (no un
# archivo estatico con @import a la paleta): un userChrome.css symlinkeado
# que hace @import a un file:// fuera de su propio directorio no se aplica
# -- el CSP del documento del chrome de Firefox lo bloquea en silencio
# (confirmado en LibreWolf 155.0, 2026-09, con pruebas aisladas). Por eso
# se symlinkea directo el archivo ya resuelto que matugen deja en
# ~/.cache/matugen/, igual que hace ya con hyprlock/waybar/etc.
ln -sf "$HOME/.cache/matugen/librewolf-userChrome.css" "$profile_dir/chrome/userChrome.css"
ln -sf "$HOME/.cache/matugen/librewolf-userContent.css" "$profile_dir/chrome/userContent.css"
rm -f "$profile_dir/chrome/matugen-colors.css" # de un esquema anterior, ya no se usa

echo "Perfil vinculado: $profile_dir"
echo "Reinicia LibreWolf para que aplique."
