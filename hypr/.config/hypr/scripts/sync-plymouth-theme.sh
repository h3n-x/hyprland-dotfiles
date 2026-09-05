#!/bin/bash
# Sincroniza el tema de Plymouth (generado por matugen en staging + estatico
# del repo) a /usr/share/plymouth/themes/ y reconstruye el initramfs. Corre
# como root.
#
# Esta es la FUENTE versionada -- lo que realmente ejecuta sudo sin password
# es una copia root-owned en /usr/local/bin/sync-plymouth-theme (ver README),
# no este archivo: como este vive en el home del usuario y es editable por
# el, apuntar el sudoers NOPASSWD directo aca equivaldria a sudo sin
# restricciones. Si editas este script, hay que volver a copiarlo con sudo
# para que aplique. Mismo patron que sync-sddm-theme.sh.
set -euo pipefail

# Corre como root via sudo -n, asi que $HOME seria /root -- se resuelve el
# home real del usuario que invoco sudo (SUDO_USER) via getent, en vez de
# asumir /home/<usuario> a mano (portable a otros esquemas de home).
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
STAGING="$USER_HOME/.cache/matugen/plymouth-theme"
REPO_THEME="$USER_HOME/Dotfiles/plymouth/theme"
DEST="/usr/share/plymouth/themes/dotfiles-matugen"

# matugen todavia no genero nada (primer stow, antes de `matugen image`) -- nada que sincronizar
[ -d "$STAGING" ] || exit 0
[ -f "$STAGING/dotfiles-matugen.script" ] || exit 0

mkdir -p "$DEST"

# Estatico: metadata del theme (no lleva colores, no lo genera matugen)
cp "$REPO_THEME/dotfiles-matugen.plymouth" "$DEST/"

# Script + fondo + avatar + frames del spinner, generados por matugen
# (post_hook del template plymouth.script -- ver matugen/.config/matugen/config.toml)
cp "$STAGING/dotfiles-matugen.script" "$DEST/"
cp "$STAGING/background.png" "$DEST/"
cp "$STAGING/avatar.png" "$DEST/"
cp "$STAGING/"frame*.png "$DEST/"

chown -R root:root "$DEST"
chmod -R a+rX "$DEST"

# -R fija este theme como default Y reconstruye el initramfs (necesario:
# Plymouth lee su theme desde dentro del initramfs, no en vivo desde disco
# como SDDM/waybar/etc).
plymouth-set-default-theme -R dotfiles-matugen

# Este equipo especifico no arranca por una entrada NVRAM con archivo
# explicito (GRUB/Limine quedaron con sus binarios borrados) -- el firmware
# cae al path de fallback UEFI generico, /boot/EFI/BOOT/BOOTX64.EFI, que es
# una copia plana de esta UKI (ver README seccion Plymouth, "arranque real
# de este equipo"). Si ese archivo existe, hay que mantenerlo sincronizado
# con la UKI recien reconstruida o el theme actualizado nunca se ve en el
# proximo arranque. Guardado en "si existe" para no tocar equipos que
# arrancan por una entrada NVRAM normal (ahi este archivo no existe/no se usa).
UKI="/boot/EFI/Linux/arch-linux-zen.efi"
if [ -f /boot/EFI/BOOT/BOOTX64.EFI ] && [ -f "$UKI" ]; then
    # Copia a un temporal en la MISMA particion + rename atomico: si la ESP
    # se queda sin espacio a mitad de la copia (paso, ver README), el rename
    # simplemente no pasa y BOOTX64.EFI queda intacto en vez de truncado.
    # `mv` entre dos paths de la misma particion es atomico (rename(2)).
    if cp "$UKI" /boot/EFI/BOOT/BOOTX64.EFI.new; then
        mv /boot/EFI/BOOT/BOOTX64.EFI.new /boot/EFI/BOOT/BOOTX64.EFI
    else
        rm -f /boot/EFI/BOOT/BOOTX64.EFI.new
        echo "sync-plymouth-theme: fallo la copia a BOOTX64.EFI.new (sin espacio?) -- BOOTX64.EFI actual quedo SIN TOCAR" >&2
        exit 1
    fi
fi
