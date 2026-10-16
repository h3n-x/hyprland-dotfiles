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
REAL_USER="${SUDO_USER:-${USER:-$(id -un)}}"
USER_HOME="${SYNC_PLYMOUTH_HOME:-$(getent passwd "$REAL_USER" | cut -d: -f6)}"
STAGING="$USER_HOME/.cache/matugen/plymouth-theme"
REPO_THEME="$USER_HOME/Dotfiles/plymouth/theme"
# Pruebas: SYNC_PLYMOUTH_ROOT (otra raiz con boot/, etc/ y usr/), SYNC_PLYMOUTH_FAKE=1 (solo dice
# que haria con los comandos del sistema), SYNC_PLYMOUTH_HOME (otro home).
ROOT="${SYNC_PLYMOUTH_ROOT:-}"
run() { if [ "${SYNC_PLYMOUTH_FAKE:-0}" = 1 ]; then echo "haria: $*"; else "$@"; fi; }
DEST="$ROOT/usr/share/plymouth/themes/dotfiles-matugen"

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

run chown -R root:root "$DEST"
chmod -R a+rX "$DEST"

# Las UKI de la ESP (rutas habituales: /boot, /efi, /boot/efi) y la copia generica de
# arranque BOOTX64.EFI que usan los equipos sin entrada NVRAM propia. Antes de reconstruir se
# anota de cual UKI es copia BOOTX64.EFI (por contenido), para volver a copiar esa misma.
ukis=()
for d in "$ROOT/boot/EFI/Linux" "$ROOT/efi/EFI/Linux" "$ROOT/boot/efi/EFI/Linux"; do
    for f in "$d"/*.efi; do [ -f "$f" ] && ukis+=("$f"); done
done
bootx=""
for d in "$ROOT/boot/EFI/BOOT" "$ROOT/efi/EFI/BOOT" "$ROOT/boot/efi/EFI/BOOT"; do
    [ -f "$d/BOOTX64.EFI" ] && { bootx="$d/BOOTX64.EFI"; break; }
done
# Mismo contenido (sha256sum, de coreutils: cmp viene de diffutils, que no esta en base).
same() { [ "$(sha256sum < "$1")" = "$(sha256sum < "$2")" ]; }
copy_of=""
if [ -n "$bootx" ]; then
    for f in "${ukis[@]}"; do same "$f" "$bootx" && { copy_of="$f"; break; }; done
    # Sin coincidencia exacta pero una sola UKI: es la que se arranca (un copiado anterior pudo fallar).
    [ -z "$copy_of" ] && [ "${#ukis[@]}" -eq 1 ] && copy_of="${ukis[0]}"
fi

# Theme por defecto sin -R: el -R del paquete de Arch llama siempre a `mkinitcpio -P`, que no
# existe (o no se usa) en los sistemas con dracut (EndeavourOS, Garuda) o booster. El initramfs
# se rehace con el generador que use este sistema (Plymouth lee el theme desde el initramfs).
run plymouth-set-default-theme dotfiles-matugen
if command -v mkinitcpio >/dev/null 2>&1 && ls "$ROOT"/etc/mkinitcpio.d/*.preset >/dev/null 2>&1; then
    run mkinitcpio -P
elif command -v dracut-rebuild >/dev/null 2>&1; then
    run dracut-rebuild
elif command -v dracut >/dev/null 2>&1; then
    run dracut --regenerate-all --force
elif [ -x /usr/lib/booster/regenerate_images ]; then
    run /usr/lib/booster/regenerate_images
else
    echo "sync-plymouth-theme: no encontre generador de initramfs (mkinitcpio, dracut, booster): el theme queda instalado pero no entra al arranque hasta que se rehaga el initramfs" >&2
    exit 1
fi

# BOOTX64.EFI sigue a la UKI de la que era copia. Copia a un temporal en la MISMA particion +
# rename atomico: si la ESP se queda sin espacio a mitad (paso, ver README), BOOTX64.EFI queda
# intacto en vez de truncado. Sin BOOTX64.EFI, o si no es copia de ninguna UKI (varias y
# distintas), no se toca: el equipo arranca por otra entrada.
if [ -n "$bootx" ] && [ -n "$copy_of" ]; then
    if cp "$copy_of" "$bootx.new"; then
        mv "$bootx.new" "$bootx"
    else
        rm -f "$bootx.new"
        echo "sync-plymouth-theme: fallo la copia a $bootx.new (sin espacio?) -- $(basename "$bootx") actual quedo SIN TOCAR" >&2
        exit 1
    fi
elif [ -n "$bootx" ]; then
    echo "sync-plymouth-theme: $bootx no es copia de ninguna UKI (hay ${#ukis[@]}): no se toca" >&2
fi
