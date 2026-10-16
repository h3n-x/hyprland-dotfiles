# shellcheck shell=bash
# shellcheck disable=SC2034  # SUMMARY_RELOGIN y SYSTEM_DONE los lee el resumen
# Paso 7 (Fase 19 B3): los pasos de sistema, opcionales. Cada uno detecta antes de preguntar y
# nunca corre con --yes solo (hace falta --with-system o el comando `system`; D-P19-5):
#   sddm      pantalla de inicio (dotfiles-login): copia de root + regla sudoers, tema, activarlo
#   plymouth  splash de arranque: hook del initramfs (mkinitcpio o dracut) y "quiet splash" en la
#             linea de comandos del kernel (UKI, systemd-boot, GRUB, Limine o rEFInd)
#   grub      tema del menu de arranque, solo si el equipo arranca con GRUB
#   gpu       hibrido: alias de udev para Hyprland en la integrada; NVIDIA: modesetting y suspension
# Archivos de arranque editados: una copia ARCHIVO.dotfiles-orig la primera vez (lib/system.sh).

SYSTEM_ALL=(sddm plymouth grub gpu)

step_system() {
    local s fail=0 steps=("${SYSTEM_STEPS[@]}")
    [ ${#steps[@]} -gt 0 ] || steps=("${SYSTEM_ALL[@]}")
    [ -n "${INIT:-}" ] || detect_init
    # Leer la ESP y /etc/sudoers.d necesita root: sudo antes de detectar, tambien en seco (en seco
    # no se escribe nada).
    if [ "${DRY:-false}" = true ]; then
        if ! sudo -n true 2>/dev/null; then
            info "Reading /boot and /etc/sudoers.d needs sudo (dry run: nothing is changed)"
            sudo -v 2>/dev/null || warn "Without sudo, /boot can't be read: the detection may be incomplete"
        fi
    else
        sudo_keepalive || return 1
    fi
    detect_boot
    info "System steps (initramfs: %1; boot loaders: %2; UKI: %3)" "$BOOT_INITRAMFS" "${BOOT_LOADERS[*]:-?}" "${#BOOT_UKIS[@]}"
    for s in "${steps[@]}"; do
        if ! "system_$s"; then fail=1; warn "The system step %1 failed (see above); the others continue" "$s"; fi
    done
    return $fail
}

# ---- SDDM ----
system_sddm() {
    ask y "Login screen: make SDDM with the dotfiles-login theme your login manager (from the next boot)?" ||
        { skipped "Login screen (SDDM)"; return 0; }
    pkg_install sddm || return 1
    sys_root_copy sddm && sys_sudoers sddm || return 1
    if [ -f "${XDG_CACHE_HOME:-$HOME/.cache}/matugen/sddm-login-colors.qml" ]; then
        do_ "$HOME/.config/hypr/scripts/sddm-theme-stage" && do_ sudo /usr/local/bin/sync-sddm-theme || return 1
    else
        warn "The login theme isn't generated yet: it is installed at the first wallpaper change (or run: ./install.sh first-run --force)"
    fi
    sys_write /etc/sddm.conf.d/theme.conf "$(printf '[Theme]\nCurrent=dotfiles-login')" || return 1
    # Activarlo sin arrancarlo: arrancar un gestor de inicio en una sesion abierta la cerraria.
    if [ "$INIT" = systemd ]; then
        local cur; cur=$(readlink "${SYSROOT:-}/etc/systemd/system/display-manager.service" 2>/dev/null)
        cur=$(basename "${cur:-none}" .service)
        if [ "$cur" = sddm ]; then ok "SDDM is already the login manager"
        else
            if [ "$cur" != none ]; then
                ask y "%1 is your login manager. Replace it with SDDM?" "$cur" || { skipped "SDDM (kept %1)" "$cur"; return 0; }
                do_ sudo systemctl disable "$cur.service" || return 1
            fi
            do_ sudo systemctl enable sddm.service || return 1
            ok "SDDM is the login manager from the next boot"
        fi
    else
        INIT_RUNNING=false svc_enable sddm sddm || return 1
        warn "On %1, also make SDDM the display manager in its configuration (e.g. /etc/conf.d/display-manager on OpenRC)" "$INIT"
    fi
    done_ "Login screen: SDDM with the dotfiles-login theme (from the next boot)"
}

# ---- Plymouth ----
system_plymouth() {
    if [ "$BOOT_INITRAMFS" = booster ]; then
        skipped "Boot splash (booster doesn't support Plymouth)"; return 0
    fi
    ask y "Boot splash: install Plymouth with the wallpaper's colors (adds its initramfs hook and \"quiet splash\" to the kernel command line)?" ||
        { skipped "Boot splash (Plymouth)"; return 0; }
    pkg_install plymouth || return 1
    sys_root_copy plymouth && sys_sudoers plymouth || return 1
    plymouth_hook || return 1
    plymouth_cmdline || return 1
    local st="${XDG_CACHE_HOME:-$HOME/.cache}/matugen/plymouth-theme"
    # Un armado de antes de la Fase 19 B3 no trae la metadata; el proximo cambio de wallpaper si.
    [ -d "$st" ] && [ ! -f "$st/dotfiles-matugen.plymouth" ] && do_ cp "$REPO_DIR/plymouth/theme/dotfiles-matugen.plymouth" "$st/"
    if [ -f "$st/dotfiles-matugen.script" ]; then
        info "Installing the theme and rebuilding the initramfs (takes a minute)"
        do_ sudo /usr/local/bin/sync-plymouth-theme || return 1
    else
        warn "The boot splash isn't generated yet: it is installed at the first wallpaper change"
    fi
    $PLY_GRUB_MKCONFIG && { do_ sudo grub-mkconfig -o /boot/grub/grub.cfg || return 1; }
    done_ "Boot splash: Plymouth (visible from the next boot)"
}

# El hook de Plymouth en el initramfs. mkinitcpio: despues de systemd o udev (o base) en HOOKS,
# en el archivo que la define al final (mkinitcpio.conf.d/ pisa a mkinitcpio.conf). dracut: un
# archivo propio en dracut.conf.d.
plymouth_hook() {
    local r=${SYSROOT:-} f file='' line new
    case "$BOOT_INITRAMFS" in
        mkinitcpio)
            for f in "$r/etc/mkinitcpio.conf" "$r"/etc/mkinitcpio.conf.d/*.conf; do
                [ -f "$f" ] && grep -qE '^HOOKS=' "$f" && file=$f
            done
            [ -n "$file" ] || { err "No HOOKS line in %1" "/etc/mkinitcpio.conf"; return 1; }
            line=$(grep -E '^HOOKS=' "$file" | tail -1)
            if [[ "$line" =~ [\(\ ]plymouth[\ \)] ]]; then ok "The initramfs already has the plymouth hook"; return 0; fi
            if [[ ! "$line" =~ ^HOOKS=\(.*\)[[:space:]]*$ ]]; then
                warn "HOOKS in %1 spans several lines: add plymouth after udev (or systemd) by hand" "${file#"$r"}"; return 1
            fi
            if [[ "$line" =~ [\(\ ]systemd[\ \)] ]]; then new=$(sed -E 's/([( ])systemd([ )])/\1systemd plymouth\2/' <<<"$line")
            elif [[ "$line" =~ [\(\ ]udev[\ \)] ]]; then new=$(sed -E 's/([( ])udev([ )])/\1udev plymouth\2/' <<<"$line")
            else new=$(sed -E 's/\(base([ )])/(base plymouth\1/' <<<"$line"); fi
            info "Adding the plymouth hook in %1" "${file#"$r"}"
            sys_backup "${file#"$r"}"
            sys_write "${file#"$r"}" "$(awk -v old="$line" -v new="$new" '$0 == old {print new; next} {print}' "$file")"
            ;;
        dracut)
            if grep -rqsE 'plymouth' "$r/etc/dracut.conf" "$r/etc/dracut.conf.d"; then ok "dracut already includes plymouth"; return 0; fi
            sys_write /etc/dracut.conf.d/dotfiles-plymouth.conf 'add_dracutmodules+=" plymouth "'
            ;;
        *) warn "Unknown initramfs generator: add Plymouth to it by hand"; return 1 ;;
    esac
}

# "quiet splash" en la linea de comandos que de verdad se usa:
#   - /etc/kernel/cmdline si hay UKI o systemd-boot (mkinitcpio y kernel-install la leen);
#   - si no, las entradas de systemd-boot, GRUB_CMDLINE_LINUX_DEFAULT (+ grub-mkconfig), Limine
#     (/etc/default/limine o limine.conf) o refind_linux.conf.
PLY_GRUB_MKCONFIG=false
plymouth_cmdline() {
    local r=${SYSROOT:-} f cur new done_any=false
    if [ -f "$r/etc/kernel/cmdline" ] && { [ ${#BOOT_UKIS[@]} -gt 0 ] || has_loader systemd-boot; }; then
        cur=$(cat "$r/etc/kernel/cmdline"); new=$(cmdline_add "$cur" quiet splash)
        [ "$cur" = "$new" ] && { ok "The kernel command line already has quiet splash"; return 0; }
        sys_backup /etc/kernel/cmdline; sys_write /etc/kernel/cmdline "$new"
        ok "Added quiet splash to %1" /etc/kernel/cmdline; return 0
    fi
    if has_loader systemd-boot; then
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            [[ "$f" == *fallback* ]] && continue
            cur=$(rcat "$f"); new=$(cmdline_lines options "$cur")
            [ "$cur" = "$new" ] && continue
            sys_backup "${f#"$r"}"; sys_write "${f#"$r"}" "$new"; done_any=true
        done < <(rsudo find "$r$BOOT_ESP/loader/entries" -maxdepth 1 -name '*.conf' 2>/dev/null ||
                 find "$r$BOOT_ESP/loader/entries" -maxdepth 1 -name '*.conf' 2>/dev/null)
        if $done_any; then ok "Added quiet splash to the systemd-boot entries"
        else ok "The systemd-boot entries already have quiet splash"; fi
        return 0
    fi
    if has_loader grub; then
        cur=$(cat "$r/etc/default/grub"); new=$(cmdline_lines grub "$cur")
        [ "$cur" = "$new" ] && { ok "GRUB's command line already has quiet splash"; return 0; }
        sys_backup /etc/default/grub; sys_write /etc/default/grub "$new"; PLY_GRUB_MKCONFIG=true
        ok "Added quiet splash to %1" /etc/default/grub; return 0
    fi
    if has_loader limine; then
        if [ -f "$r/etc/default/limine" ]; then
            # CachyOS (limine-entry-tool): una linea propia que suma a la de por defecto.
            if grep -qE '\bsplash\b' "$r/etc/default/limine"; then ok "Limine's command line already has splash"; return 0; fi
            sys_backup /etc/default/limine
            sys_write /etc/default/limine "$(cat "$r/etc/default/limine"; printf '%s\n' '# Plymouth (lo agrego el instalador de los dotfiles)' 'KERNEL_CMDLINE[default]+=" quiet splash"')"
            command -v limine-update >/dev/null 2>&1 && do_ sudo limine-update
            ok "Added quiet splash to %1" /etc/default/limine; return 0
        fi
        for f in /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf; do
            rfile "$r$f" || continue
            cur=$(rcat "$r$f"); new=$(cmdline_lines limine "$cur")
            [ "$cur" = "$new" ] && { ok "Limine's command line already has quiet splash"; return 0; }
            sys_backup "$f"; sys_write "$f" "$new"; ok "Added quiet splash to %1" "$f"; return 0
        done
    fi
    if has_loader refind; then
        cur=$(rcat "$r/boot/refind_linux.conf"); new=$(cmdline_lines refind "$cur")
        [ "$cur" = "$new" ] && { ok "rEFInd's command line already has quiet splash"; return 0; }
        sys_backup /boot/refind_linux.conf; sys_write /boot/refind_linux.conf "$new"
        ok "Added quiet splash to %1" /boot/refind_linux.conf; return 0
    fi
    warn "Couldn't tell which boot loader starts this system: add \"quiet splash\" to the kernel command line by hand"
    return 0
}

# cmdline_lines FORMATO TEXTO: el texto con "quiet splash" en las lineas de opciones del kernel.
cmdline_lines() {
    local fmt=$1 l pre val post
    while IFS= read -r l || [ -n "$l" ]; do
        case "$fmt" in
            options) if [[ "$l" =~ ^(options[[:space:]]+)(.*)$ ]]; then l="${BASH_REMATCH[1]}$(cmdline_add "${BASH_REMATCH[2]}" quiet splash)"; fi ;;
            grub)    if [[ "$l" =~ ^(GRUB_CMDLINE_LINUX_DEFAULT=)([\"\']?)(.*)([\"\']?)$ ]]; then
                         pre=${BASH_REMATCH[1]}${BASH_REMATCH[2]}; val=${BASH_REMATCH[3]}; post=${BASH_REMATCH[2]}
                         val=${val%"$post"}; l="$pre$(cmdline_add "$val" quiet splash)$post"; fi ;;
            limine)  if [[ "$l" =~ ^([[:space:]]*(kernel_cmdline|cmdline|CMDLINE)[[:space:]]*[:=][[:space:]]*)(.*)$ ]]; then
                         l="${BASH_REMATCH[1]}$(cmdline_add "${BASH_REMATCH[3]}" quiet splash)"; fi ;;
            refind)  if [[ "$l" =~ ^(\"[^\"]*\"[[:space:]]+\")([^\"]*)(\".*)$ ]] && [[ "$l" != *[Ff]allback* ]]; then
                         l="${BASH_REMATCH[1]}$(cmdline_add "${BASH_REMATCH[2]}" quiet splash)${BASH_REMATCH[3]}"; fi ;;
        esac
        printf '%s\n' "$l"
    done <<<"$2"
}

# ---- GRUB ----
system_grub() {
    has_loader grub || { skipped "GRUB theme (this system doesn't boot with GRUB)"; return 0; }
    ask y "GRUB theme: the wallpaper's colors in the boot menu?" || { skipped "GRUB theme"; return 0; }
    sys_root_copy grub && sys_sudoers grub || return 1
    local st="${XDG_CACHE_HOME:-$HOME/.cache}/matugen/grub-theme"
    if [ -f "$st/theme.txt" ]; then
        # Un armado de antes de la Fase 19 B3 no trae las fuentes; el proximo cambio de wallpaper si.
        [ -f "$st/font.pf2" ] || do_ cp "$REPO_DIR/grub/theme/font.pf2" "$REPO_DIR/grub/theme/font-bold.pf2" "$st/"
        do_ sudo /usr/local/bin/sync-grub-theme || return 1
    else
        warn "The GRUB theme isn't generated yet: it is installed at the first wallpaper change"
    fi
    done_ "GRUB theme with the wallpaper's colors"
}

# ---- GPU ----
system_gpu() {
    local gs="$REPO_DIR/hypr/.config/hypr/scripts/gpu-setup" kind rule s
    kind=$("$gs" 2>/dev/null | sed -nE 's/.*Caso: ([a-z]+).*/\1/p' | head -1)
    case "$kind" in
        hybrid|nvidia) ;;
        *) ok "No hybrid or NVIDIA GPU: nothing to set up (%1)" "${kind:-none}"; return 0 ;;
    esac
    ask y "GPU (%1): udev aliases so Hyprland runs on the integrated GPU, NVIDIA modesetting and suspend services?" "$kind" ||
        { skipped "GPU setup"; return 0; }
    if [ "$kind" = hybrid ] && rule=$("$gs" --udev-rule 2>/dev/null); then
        local uf="${SYSROOT:-}/etc/udev/rules.d/71-gpu-drm-aliases.rules"
        # Las mismas reglas (sin importar orden ni comentarios): se deja la que ya esta.
        if [ -f "$uf" ] && [ "$(grep -vE '^\s*(#|$)' "$uf" | sort)" = "$(grep -vE '^\s*(#|$)' <<<"$rule" | sort)" ]; then
            ok "The GPU udev aliases are already in place"
        else
            sys_write /etc/udev/rules.d/71-gpu-drm-aliases.rules "$rule" || return 1
            do_ sudo udevadm control --reload && do_ sudo udevadm trigger --subsystem-match=drm
        fi
        do_ "$gs" --write   # con los alias ya creados, AQ_DRM_DEVICES con la integrada primero
        SUMMARY_RELOGIN=true
    fi
    # nvidia-utils ya trae modeset=1 en las versiones nuevas; si no, se agrega.
    if grep -rqsE 'nvidia[-_]drm.*modeset=1' "${SYSROOT:-}/etc/modprobe.d" "${SYSROOT:-}/usr/lib/modprobe.d"; then
        ok "NVIDIA modesetting is already on"
    else
        sys_write /etc/modprobe.d/nvidia.conf "options nvidia_drm modeset=1" || return 1
    fi
    if [ "$INIT" = systemd ]; then
        for s in nvidia-suspend nvidia-hibernate nvidia-resume; do
            [ -f "${SYSROOT:-}/usr/lib/systemd/system/$s.service" ] || continue
            systemctl is-enabled --quiet "$s" 2>/dev/null || do_ sudo systemctl enable "$s.service"
        done
    fi
    done_ "GPU: %1 set up (takes effect at the next boot)" "$kind"
}

# Al final de `install`: los pasos de sistema solo con --with-system, o si se acepta la pregunta
# (por defecto no). Con --yes sin --with-system se omiten (D-P19-5).
step_system_gate() {
    if $WITH_SYSTEM || { [ "${YES:-false}" != true ] && [ -t 0 ] &&
        ask n "Set up the optional system steps now (login screen, boot splash, GRUB theme, GPU)? Each one asks first"; }; then
        SYSTEM_DONE=true
        step_system
    else
        skipped "System steps (run: ./install.sh system)"
    fi
}
