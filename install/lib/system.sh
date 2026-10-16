# shellcheck shell=bash
# shellcheck disable=SC2034  # BOOT_* los usa steps/70-system.sh
# Pasos de sistema (Fase 19 B3): deteccion del arranque y ayudantes para tocar archivos de root.
# Se carga con `source`; necesita lib/ui.sh. SYSROOT (pruebas) antepone otra raiz a /etc y /boot.

# rsudo CMD...: leer como root sin pedir contrasena (step_system ya pidio sudo; si no hay sudo
# vigente, cuenta como que no se pudo leer).
rsudo() { sudo -n "$@" 2>/dev/null; }

# rexists RUTA / rfile RUTA / rdir RUTA: como test -e/-f/-d, y si no se puede leer (la ESP suele
# ser solo de root: /boot drwx------), como root.
rexists() { [ -e "$1" ] || rsudo test -e "$1"; }
rfile() { [ -f "$1" ] || rsudo test -f "$1"; }
rdir() { [ -d "$1" ] || rsudo test -d "$1"; }
# rcat ARCHIVO: su contenido, leido como root si hace falta.
rcat() { if [ -r "$1" ]; then cat "$1"; else rsudo cat "$1"; fi; }

# detect_boot: BOOT_INITRAMFS (mkinitcpio | dracut | booster | unknown), BOOT_UKIS (las UKI de la
# ESP), BOOT_LOADERS (los que hay: grub systemd-boot limine refind), BOOT_ESP.
detect_boot() {
    local r=${SYSROOT:-} d f
    BOOT_INITRAMFS=unknown
    if [ -f "$r/etc/mkinitcpio.conf" ] && command -v mkinitcpio >/dev/null 2>&1; then BOOT_INITRAMFS=mkinitcpio
    elif command -v dracut >/dev/null 2>&1; then BOOT_INITRAMFS=dracut
    elif command -v booster >/dev/null 2>&1; then BOOT_INITRAMFS=booster; fi
    BOOT_ESP=
    for d in /boot /efi /boot/efi; do rdir "$r$d/EFI" && { BOOT_ESP=$d; break; }; done
    BOOT_UKIS=()
    for d in /boot /efi /boot/efi; do
        rdir "$r$d/EFI/Linux" || continue
        while IFS= read -r f; do [ -n "$f" ] && BOOT_UKIS+=("${f#"$r"}"); done < <(rsudo find "$r$d/EFI/Linux" -maxdepth 1 -name '*.efi' 2>/dev/null ||
            find "$r$d/EFI/Linux" -maxdepth 1 -name '*.efi' 2>/dev/null)
    done
    BOOT_LOADERS=()
    { [ -f "$r/etc/default/grub" ] && rdir "$r/boot/grub"; } && BOOT_LOADERS+=(grub)
    [ -n "$BOOT_ESP" ] && rfile "$r$BOOT_ESP/loader/loader.conf" && BOOT_LOADERS+=(systemd-boot)
    for f in /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf /etc/default/limine; do
        rfile "$r$f" && { BOOT_LOADERS+=(limine); break; }
    done
    rfile "$r/boot/refind_linux.conf" && BOOT_LOADERS+=(refind)
    return 0
}

has_loader() { [[ " ${BOOT_LOADERS[*]} " == *" $1 "* ]]; }

# sys_write ARCHIVO CONTENIDO: lo escribe como root (0644) solo si cambia.
sys_write() {
    local f="${SYSROOT:-}$1"
    rfile "$f" && [ "$(rcat "$f")" = "$2" ] && return 0
    if [ "${DRY:-false}" = true ]; then do_ "sudo tee $f"; printf '%s\n' "$2" | sed 's/^/     /'; return 0; fi
    log_ "escribe: $f"
    sudo mkdir -p "$(dirname "$f")" && printf '%s\n' "$2" | sudo tee "$f" >/dev/null
}

# sys_backup ARCHIVO: una copia ARCHIVO.dotfiles-orig la primera vez que el instalador lo edita.
# Excepcion argumentada a "sin respaldos": son archivos de arranque (mkinitcpio.conf, la linea de
# comandos del kernel); si algo sale mal se arregla desde un USB con la copia al lado.
sys_backup() {
    local f="${SYSROOT:-}$1"
    rfile "$f" && ! rexists "$f.dotfiles-orig" && do_ sudo cp -p "$f" "$f.dotfiles-orig"
    return 0
}

# sys_root_copy NOMBRE: instala hypr/.../scripts/sync-NOMBRE-theme.sh como copia de root en
# /usr/local/bin/sync-NOMBRE-theme (la que corre sudo sin contrasena; la del repo es editable por
# el usuario y apuntar sudoers ahi seria sudo sin limites).
sys_root_copy() {
    local src="$REPO_DIR/hypr/.config/hypr/scripts/sync-$1-theme.sh" dst="${SYSROOT:-}/usr/local/bin/sync-$1-theme"
    if [ -f "$dst" ] && [ "$(sha256sum < "$dst")" = "$(sha256sum < "$src")" ]; then
        ok "%1 is up to date" "$dst"; return 0
    fi
    do_ sudo install -D -m 755 -o root -g root "$src" "$dst" || return 1
    [ "${DRY:-false}" = true ] || ok "Installed %1" "$dst"
}

# sys_sudoers NOMBRE: la regla que deja correr SOLO esa copia sin contrasena (el cambio de
# wallpaper la llama con sudo -n). visudo la valida antes de instalarla: un error ahi rompe sudo.
sys_sudoers() {
    local f="${SYSROOT:-}/etc/sudoers.d/matugen-$1" rule tmp
    rule="$USER ALL=(root) NOPASSWD: /usr/local/bin/sync-$1-theme"
    # Ya permitido sin contrasena (esta regla u otra equivalente de antes): nada que hacer.
    if [ -z "${SYSROOT:-}" ] && sudo_nopasswd "/usr/local/bin/sync-$1-theme"; then
        ok "sudoers rule for %1 is in place" "$1"; return 0
    fi
    if rsudo test -f "$f" && [ "$(rsudo cat "$f")" = "$rule" ]; then ok "sudoers rule for %1 is in place" "$1"; return 0; fi
    if [ "${DRY:-false}" = true ]; then do_ "visudo -c && sudo install -m 440 (sudoers: $rule) $f"; return 0; fi
    tmp=$(mktemp)
    printf '%s\n' "$rule" > "$tmp"
    if ! sudo visudo -c -q -f "$tmp" >/dev/null; then rm -f "$tmp"; err "visudo rejected the rule: nothing installed"; return 1; fi
    sudo install -D -m 440 -o root -g root "$tmp" "$f"
    rm -f "$tmp"
    ok "Installed the sudoers rule %1" "$f"
}

# cmdline_add TEXTO PALABRA...: el texto con las palabras que le falten al final.
cmdline_add() {
    local s=$1 w; shift
    for w in "$@"; do [[ " $s " == *" $w "* ]] || s="${s:+$s }$w"; done
    printf '%s\n' "$s"
}
