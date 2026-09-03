#!/bin/bash
# Sincroniza el tema de SDDM (generado por matugen en staging + estatico del
# repo) a /usr/share/sddm/themes/. Corre como root.
#
# Esta es la FUENTE versionada -- lo que realmente ejecuta sudo sin password
# es una copia root-owned en /usr/local/bin/sync-sddm-theme (ver README), no
# este archivo: como este vive en el home del usuario y es editable por el,
# apuntar el sudoers NOPASSWD directo aca equivaldria a sudo sin restricciones.
# Si editas este script, hay que volver a copiarlo con sudo para que aplique.
set -euo pipefail

# Corre como root via sudo -n, asi que $HOME seria /root -- se resuelve el
# home real del usuario que invoco sudo (SUDO_USER) via getent, en vez de
# asumir /home/<usuario> a mano (portable a otros esquemas de home).
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
STAGING="$USER_HOME/.cache/matugen/sddm-theme"
REPO_THEME="$USER_HOME/Dotfiles/sddm/theme"
DEST="/usr/share/sddm/themes/dotfiles-matugen"
WALLPAPER_CONF="$USER_HOME/.config/hypr/current-wallpaper.conf"

# matugen todavia no genero nada (primer stow, antes de `matugen image`) -- nada que sincronizar
[ -d "$STAGING" ] || exit 0
[ -f "$STAGING/Main.qml" ] || exit 0

mkdir -p "$DEST/backgrounds" "$DEST/Components"

# Estatico: iconos, assets, theme.conf, metadata.desktop, licencia
cp -r "$REPO_THEME/icons" "$DEST/"
cp -r "$REPO_THEME/assets" "$DEST/"
cp "$REPO_THEME/theme.conf" "$DEST/"
cp "$REPO_THEME/metadata.desktop" "$DEST/"
cp "$REPO_THEME/LICENSE-catppuccin" "$DEST/"

# QML generado por matugen
cp "$STAGING/Main.qml" "$DEST/"
cp "$STAGING/Components/"*.qml "$DEST/Components/"

# Wallpaper actual -- SDDM corre como el usuario "sddm", no puede leer dentro
# de /home/h3n (permisos 700), asi que se copia la imagen real a un lugar
# que si puede leer en vez de symlinkear al home.
if [ -f "$WALLPAPER_CONF" ]; then
  wallpaper_path=$(grep -oP '(?<=path = ).*' "$WALLPAPER_CONF" | head -1 | sed "s|^~|$USER_HOME|")
  if [ -n "$wallpaper_path" ] && [ -f "$wallpaper_path" ]; then
    cp "$wallpaper_path" "$DEST/backgrounds/wall.png"
  fi
fi

chown -R root:root "$DEST"
chmod -R a+rX "$DEST"
