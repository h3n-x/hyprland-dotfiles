#!/bin/bash
# Instala el tema del greeter de SDDM (Fase 9 B3) que armo el usuario con
# scripts/sddm-theme-stage en ~/.cache/matugen/sddm-login/ en
# /usr/share/sddm/themes/dotfiles-login. Corre como root.
#
# Esta es la FUENTE versionada -- lo que realmente ejecuta sudo sin password
# es una copia root-owned en /usr/local/bin/sync-sddm-theme (ver README), no
# este archivo: como este vive en el home del usuario y es editable por el,
# apuntar el sudoers NOPASSWD directo aca equivaldria a sudo sin restricciones.
# Si editas este script, hay que volver a copiarlo con sudo para que aplique.
#
# Sin argumentos ni variables: el destino es fijo. Root no arma nada ni lee
# el home fuera del directorio armado, y rechaza enlaces simbolicos (un
# enlace en el armado podria apuntar a cualquier archivo del sistema). El
# reemplazo es atomico: un directorio temporal junto al destino y un mv.
set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
STAGE="$USER_HOME/.cache/matugen/sddm-login"
THEMES=/usr/share/sddm/themes
DEST="$THEMES/dotfiles-login"

# Todavia no hay nada armado (primer arranque).
[ -f "$STAGE/Main.qml" ] || exit 0

if [ -n "$(find "$STAGE" -type l -print -quit)" ]; then
  echo "sync-sddm-theme: el armado tiene enlaces simbolicos: no se instala" >&2
  exit 1
fi

tmp=$(mktemp -d "$THEMES/.dotfiles-login.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
cp -r "$STAGE/." "$tmp/"
chown -R root:root "$tmp"
chmod -R u=rwX,go=rX "$tmp"
rm -rf "$DEST"
mv "$tmp" "$DEST"
trap - EXIT
