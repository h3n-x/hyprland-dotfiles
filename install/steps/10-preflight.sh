# shellcheck shell=bash
# shellcheck disable=SC2034  # SUDO_KEEPALIVE lo cierra el trap de install.sh
# Paso 1 (Fase 19 B2): que el equipo sirva antes de tocar nada. Distribucion (Arch o derivada),
# x86_64, no root, sudo, pacman libre, red, espacio; actualiza el sistema (sin actualizacion
# parcial) salvo --skip-sysupdate.

step_preflight() {
    info "Checking the system"
    detect_distro
    case "$DISTRO_GROUP" in
        arch) ok "Distribution: %1" "${DISTRO_NAME:-$DISTRO_ID}" ;;
        arch-alike) warn "%1 is not a known Arch-based distribution, but says it is like Arch: continuing" "${DISTRO_NAME:-$DISTRO_ID}" ;;
        *) err "This installer is for Arch Linux and distributions based on it (found: %1)" "${DISTRO_NAME:-unknown}"; return 1 ;;
    esac
    command -v pacman >/dev/null 2>&1 || { err "pacman not found"; return 1; }
    [ "$(uname -m)" = x86_64 ] || warn "Only x86_64 is tested (this is %1)" "$(uname -m)"
    [ "$(id -u)" -ne 0 ] || { err "Run it as your user, not as root: it asks for sudo when needed"; return 1; }
    [ "$DISTRO_ID" = artix ] && warn "Artix: services are enabled for OpenRC, runit, dinit or s6 on a best-effort basis"
    [ "$DISTRO_ID" = manjaro ] && info "Manjaro: its packages arrive weeks after Arch; the version check will say if Hyprland is too old"
    detect_init
    ok "Init system: %1" "$INIT"

    # sudo una vez, y vivo mientras dure el instalador.
    if [ "${DRY:-false}" != true ]; then
        sudo -v || { err "sudo is needed to install packages"; return 1; }
        ( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 50; done ) &
        SUDO_KEEPALIVE=$!
    fi
    if [ -e /var/lib/pacman/db.lck ]; then
        err "pacman is busy (/var/lib/pacman/db.lck): wait for the other update to finish"; return 1
    fi
    local free; free=$(df -Pm / | awk 'NR == 2 {print $4}')
    [ "${free:-0}" -ge 3000 ] || warn "Less than 3 GB free on / (%1 MB)" "$free"

    [ "$DISTRO_ID" = artix ] && { artix_arch_repos || return 1; }

    # Arch no soporta actualizaciones parciales: -Syu antes de instalar nada.
    if [ "${SKIP_SYSUPDATE:-false}" = true ]; then
        skipped "System update (--skip-sysupdate)"
    else
        info "Updating the system"
        # Con preguntas, pacman pregunta lo suyo (reemplazos, conflictos); con --yes, lo de por defecto.
        local nc=(); [ "${YES:-false}" = true ] && nc=(--noconfirm)
        do_ sudo pacman -Syu "${nc[@]}" || { err "The system update failed"; return 1; }
    fi
}

# Artix: matugen, tdf, glow... solo estan en los repos de Arch. Se activan como dice la wiki de
# Artix: artix-archlinux-support (llaves y mirrorlist-arch) y [extra] al final de pacman.conf.
artix_arch_repos() {
    grep -q '^\[extra\]' /etc/pacman.conf && return 0
    if ! ask y "Artix: some packages (matugen, glow, tdf...) are only in Arch's repositories. Enable them (artix-archlinux-support)?"; then
        skipped "Arch's repositories on Artix: matugen and other packages will be missing"
        return 0
    fi
    do_ sudo pacman -Sy --needed --noconfirm artix-archlinux-support || { err "Could not install artix-archlinux-support"; return 1; }
    if [ "${DRY:-false}" = true ]; then do_ "printf '[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n' | sudo tee -a /etc/pacman.conf"
    else printf '\n# Repos de Arch (artix-archlinux-support), los agrego el instalador de los dotfiles\n[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n' |
        sudo tee -a /etc/pacman.conf >/dev/null; fi
    do_ sudo pacman-key --populate archlinux
    done_ "Enabled Arch's [extra] repository on Artix"
}
