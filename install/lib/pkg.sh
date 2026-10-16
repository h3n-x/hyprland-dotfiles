# shellcheck shell=bash
# Paquetes (Fase 19 B2): pacman con los conflictos preguntados antes, el AUR por yay o paru y
# la lista de lo que el instalador agrego (la usa `uninstall`). Se carga con `source`; necesita
# lib/ui.sh, lib/detect.sh, STATE, DRY, YES y NO_AUR.

# Paquetes que el instalador agrego (uno por linea): uninstall solo quita estos.
PKG_RECORD() { printf '%s\n' "$STATE/installed-packages"; }

pkg_installed() { pacman -Qq "$1" >/dev/null 2>&1; }

# pkg_record PAQUETE...: anota los que no estaban (sin repetir).
pkg_record() {
    [ $# -eq 0 ] && return 0
    [ "${DRY:-false}" = true ] && return 0
    mkdir -p "$STATE"
    { cat "$(PKG_RECORD)" 2>/dev/null; printf '%s\n' "$@"; } | sort -u > "$(PKG_RECORD).tmp"
    mv "$(PKG_RECORD).tmp" "$(PKG_RECORD)"
}

# pkg_conflicts PAQUETE...: "instalado|pedido" por cada paquete instalado con el que choca uno
# de los pedidos (Conflicts With de pacman -Si; "pacman -T" resuelve tambien los provides).
pkg_conflicts() {
    [ $# -eq 0 ] && return 0
    LC_ALL=C pacman -Si "$@" 2>/dev/null | awk -F' : ' '
        /^Name/ { name = $2 }
        /^Conflicts With/ { if ($2 != "None") { n = split($2, c, /  +/); for (i = 1; i <= n; i++) print c[i] "|" name } }' |
    while IFS='|' read -r c want; do
        c=${c%%[<>=]*}
        [ -z "$c" ] || [ "$c" = "$want" ] && continue
        # Satisfecho = algo instalado se llama asi o lo provee.
        [ -z "$(pacman -T "$c" 2>/dev/null)" ] || continue
        printf '%s|%s\n' "$c" "$want"
    done
}

# pkg_install PAQUETE...: instala los que falten de los repos. Los que el repo no tiene se
# avisan y se omiten (Manjaro puede no tenerlos aun); los conflictos se preguntan antes.
pkg_install() {
    local p want=() absent=() drop=() ask4=() before c w
    local -A sync=()
    while read -r p; do sync[$p]=1; done < <(pacman -Slq 2>/dev/null)
    # Sin bases de datos de los repos (nunca se hizo -Sy) todo pareceria "no existe".
    if [ ${#sync[@]} -eq 0 ]; then
        err "pacman has no package databases yet: run the installer without --skip-sysupdate (or: sudo pacman -Sy)"
        return 1
    fi
    for p in "$@"; do
        pkg_installed "$p" && continue
        if [ -n "${sync[$p]:-}" ]; then want+=("$p"); else absent+=("$p"); fi
    done
    [ ${#absent[@]} -gt 0 ] && warn "Not in this distribution's repositories (skipped): %1" "${absent[*]}"
    [ ${#want[@]} -eq 0 ] && { ok "Nothing to install from the repositories"; return 0; }
    # Conflictos: pipewire-pulse reemplaza a pulseaudio, etc. Si se acepta, pacman los quita
    # (--ask=4 contesta "si" a "quitar el paquete en conflicto"); si no, ese pedido se omite.
    while IFS='|' read -r c w; do
        if ask y "%1 conflicts with the installed %2. Replace %2 with %1?" "$w" "$c"; then ask4=(--ask=4)
        else drop+=("$w"); skipped "%1 (conflicts with %2, kept %2)" "$w" "$c"; fi
    done < <(pkg_conflicts "${want[@]}")
    if [ ${#drop[@]} -gt 0 ]; then
        local keep=()
        for p in "${want[@]}"; do [[ " ${drop[*]} " == *" $p "* ]] || keep+=("$p"); done
        want=("${keep[@]}")
    fi
    [ ${#want[@]} -eq 0 ] && return 0
    info "Installing %1 packages from the repositories" "${#want[@]}"
    # En la prueba en seco pacman resuelve las dependencias igual (-Sp no instala nada).
    if [ "${DRY:-false}" = true ]; then
        if pacman -Sp --print-format '%n' "${want[@]}" >/dev/null; then ok "pacman resolves all %1 packages" "${#want[@]}"
        else err "pacman cannot resolve the packages (see the message above)"; return 1; fi
    fi
    before=$(pacman -Qq | sort)
    if ! do_ sudo pacman -S --needed --noconfirm "${ask4[@]}" "${want[@]}"; then
        err "pacman could not install the packages (see the message above)"
        return 1
    fi
    # Anota lo nuevo, dependencias incluidas: son las que uninstall puede quitar.
    [ "${DRY:-false}" = true ] && return 0
    mapfile -t p < <(comm -13 <(printf '%s\n' "$before") <(pacman -Qq | sort))
    pkg_record "${p[@]}"
    done_ "Installed %1 packages" "${#p[@]}"
}

# aur_bootstrap: instala yay-bin desde el AUR (base-devel, git y makepkg como tu usuario).
aur_bootstrap() {
    local tmp
    info "Installing the AUR helper yay"
    pkg_install base-devel git || return 1
    tmp=$(mktemp -d)
    do_ git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" || { rm -rf "$tmp"; return 1; }
    if [ "${DRY:-false}" = true ]; then do_ makepkg -si --noconfirm; rm -rf "$tmp"; AUR_HELPER=yay; return 0; fi
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm) || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
    pkg_record yay-bin yay-bin-debug
    AUR_HELPER=yay
}

# aur_install GRUPO...: los paquetes de aur.txt de esos grupos. Sin ayudante de AUR (o con
# --no-aur), su alternativa de los repos, si tiene; los demas quedan avisados.
aur_install() {
    local p g alt want=() alts=() lost=() before
    while read -r p g alt _; do
        [[ " $* " == *" $g "* ]] || continue
        pkg_installed "$p" && continue
        want+=("$p")
        if [ "$alt" != - ]; then alts+=("$alt"); else lost+=("$p"); fi
    done < <(grep -vE '^\s*(#|$)' "${INSTALL_DIR:-$REPO_DIR/install}/packages/aur.txt")
    [ ${#want[@]} -eq 0 ] && return 0
    # Algunas distros ya los tienen compilados en un repo (Chaotic-AUR en Garuda, los de CachyOS):
    # por pacman, sin compilar nada.
    local -A sync=(); local inrepo=() rest=()
    while read -r p; do sync[$p]=1; done < <(pacman -Slq 2>/dev/null)
    for p in "${want[@]}"; do if [ -n "${sync[$p]:-}" ]; then inrepo+=("$p"); else rest+=("$p"); fi; done
    if [ ${#inrepo[@]} -gt 0 ]; then
        info "Already built in a repository: %1" "${inrepo[*]}"
        pkg_install "${inrepo[@]}" || return 1
        want=("${rest[@]}")
        [ ${#want[@]} -eq 0 ] && return 0
    fi
    if [ "${NO_AUR:-false}" != true ] && ! detect_aur_helper; then
        if ask y "These packages are in the AUR: %1. Install the AUR helper yay to get them?" "${want[*]}"; then
            aur_bootstrap || warn "Could not install yay"
        fi
    fi
    if [ "${NO_AUR:-false}" = true ] || [ -z "${AUR_HELPER:-}" ]; then
        [ ${#alts[@]} -gt 0 ] && { info "Without the AUR: installing the alternatives from the repositories"; pkg_install "${alts[@]}"; }
        [ ${#lost[@]} -gt 0 ] && { warn "Without the AUR these stay missing: %1" "${lost[*]}"; skipped "AUR packages: %1" "${lost[*]}"; }
        return 0
    fi
    # Compilar del AUR necesita base-devel (fakeroot, debugedit...), aunque la distro traiga el ayudante.
    pkg_install base-devel git || return 1
    info "Installing %1 packages from the AUR with %2" "${#want[@]}" "$AUR_HELPER"
    before=$(pacman -Qq | sort)
    case "$AUR_HELPER" in
        yay)  do_ yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "${want[@]}" ;;
        paru) do_ paru -S --needed --noconfirm --skipreview --removemake "${want[@]}" ;;
        *)    do_ "$AUR_HELPER" -S --needed --noconfirm "${want[@]}" ;;
    esac || warn "Some AUR packages failed (see the message above)"
    [ "${DRY:-false}" = true ] && return 0
    mapfile -t p < <(comm -13 <(printf '%s\n' "$before") <(pacman -Qq | sort))
    pkg_record "${p[@]}"
    [ ${#p[@]} -gt 0 ] && done_ "Installed %1 packages from the AUR" "${#p[@]}"
    return 0
}
