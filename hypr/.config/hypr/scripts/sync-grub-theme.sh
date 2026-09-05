#!/bin/bash
# Sincroniza el tema de GRUB (generado por matugen en staging) a
# /boot/grub/themes/, asegura GRUB_THEME en /etc/default/grub y regenera
# grub.cfg. Corre como root.
#
# Esta es la FUENTE versionada -- lo que realmente ejecuta sudo sin password
# es una copia root-owned en /usr/local/bin/sync-grub-theme (ver README), no
# este archivo: como este vive en el home del usuario y es editable por el,
# apuntar el sudoers NOPASSWD directo aca equivaldria a sudo sin
# restricciones. Si editas este script, hay que volver a copiarlo con sudo
# para que aplique. Mismo patron que sync-sddm-theme.sh / sync-plymouth-theme.sh.
set -euo pipefail

# Corre como root via sudo -n, asi que $HOME seria /root -- se resuelve el
# home real del usuario que invoco sudo (SUDO_USER) via getent, en vez de
# asumir /home/<usuario> a mano (portable a otros esquemas de home).
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
STAGING="$USER_HOME/.cache/matugen/grub-theme"
REPO_THEME="$USER_HOME/Dotfiles/grub/theme"
DEST="/boot/grub/themes/dotfiles-matugen"

# matugen todavia no genero nada (primer stow, antes de `matugen image`) -- nada que sincronizar
[ -d "$STAGING" ] || exit 0
[ -f "$STAGING/theme.txt" ] || exit 0

mkdir -p "$DEST"

# Estatico: fuentes (JetBrains Mono Nerd Font, generadas una vez con
# grub-mkfont -- no dependen de colores, no las genera matugen). grub-mkconfig
# las carga solo por estar en la carpeta del theme.
cp "$REPO_THEME/font.pf2" "$DEST/"
cp "$REPO_THEME/font-bold.pf2" "$DEST/"

# theme.txt (matugen) + fondo/avatar/tick/pill de seleccion (ImageMagick,
# generate-grub-assets.sh)
cp "$STAGING/theme.txt" "$DEST/"
cp "$STAGING/background.png" "$DEST/"
cp "$STAGING/avatar.png" "$DEST/"
cp "$STAGING/tick.png" "$DEST/"
cp "$STAGING/select_w.png" "$DEST/"
cp "$STAGING/select_c.png" "$DEST/"
cp "$STAGING/select_e.png" "$DEST/"

chown -R root:root "$DEST"
chmod -R a+rX "$DEST"

# Asegura GRUB_THEME en /etc/default/grub -- idempotente: pisa la linea si
# ya existe (activa o comentada), la agrega si no existe ninguna.
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/dotfiles-matugen/theme.txt"'
if grep -q '^GRUB_THEME=' /etc/default/grub; then
    sed -i "s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" /etc/default/grub
elif grep -q '^#GRUB_THEME=' /etc/default/grub; then
    sed -i "s|^#GRUB_THEME=.*|$GRUB_THEME_LINE|" /etc/default/grub
else
    echo "$GRUB_THEME_LINE" >> /etc/default/grub
fi

# Rebuild liviano (sin UKI de por medio, a diferencia de Plymouth) -- lee
# el theme.txt recien copiado y lo hornea en grub.cfg.
grub-mkconfig -o /boot/grub/grub.cfg
