# shellcheck shell=bash
# shellcheck disable=SC2034  # DISTRO_*, INIT y MIN_VERSIONS los usa quien carga la libreria
# Deteccion del sistema (Fase 19). Se carga con `source`; las pruebas cambian OS_RELEASE.

# Distribucion: DISTRO_ID, DISTRO_LIKE (de os-release) y DISTRO_GROUP (arch | arch-alike | other).
detect_distro() {
    local f=${OS_RELEASE:-/etc/os-release}
    DISTRO_ID=$(awk -F= '/^ID=/{gsub(/["'\'']/,"",$2); print tolower($2)}' "$f" 2>/dev/null)
    DISTRO_LIKE=$(awk -F= '/^ID_LIKE=/{gsub(/["'\'']/,"",$2); print tolower($2)}' "$f" 2>/dev/null)
    case "$DISTRO_ID" in
        arch|endeavouros|cachyos|manjaro|garuda|artix|arcolinux|rebornos|archcraft|blendos) DISTRO_GROUP=arch ;;
        *) if [[ " $DISTRO_LIKE " == *" arch "* ]]; then DISTRO_GROUP=arch-alike; else DISTRO_GROUP=other; fi ;;
    esac
}

# Sistema de init: INIT = systemd | openrc | runit | dinit | s6 | unknown.
detect_init() {
    local p1; p1=$(cat /proc/1/comm 2>/dev/null)
    if [ -d /run/systemd/system ]; then INIT=systemd
    elif command -v openrc >/dev/null 2>&1 || [ "$p1" = openrc-init ]; then INIT=openrc
    elif [ "$p1" = runit ] || command -v sv >/dev/null 2>&1; then INIT=runit
    elif [ "$p1" = dinit ] || command -v dinitctl >/dev/null 2>&1; then INIT=dinit
    elif [ "$p1" = s6-svscan ] || command -v s6-rc >/dev/null 2>&1; then INIT=s6
    else INIT=unknown; fi
}

# pkg_version PAQUETE: la version instalada (vacio si no esta).
pkg_version() { pacman -Q "$1" 2>/dev/null | awk '{print $2}'; }

# version_at_least PAQUETE MINIMA: 0 si la instalada es >= la minima (vercmp de pacman).
version_at_least() {
    local v; v=$(pkg_version "$1")
    [ -n "$v" ] && [ "$(vercmp "$v" "$2")" -ge 0 ]
}

# Versiones minimas que la config necesita (Lua de Hyprland, Networking de Quickshell, matugen 4).
MIN_VERSIONS="hyprland:0.56 quickshell:0.3 matugen:4.0"

# Paquetes de "stow" del repo: toda carpeta de primer nivel salvo las que no se enlazan.
NO_STOW="git sddm grub plymouth install"
stow_packages() {
    local d
    for d in "$REPO_DIR"/*/; do
        d=$(basename "$d")
        [[ " $NO_STOW " == *" $d "* ]] && continue
        printf '%s\n' "$d"
    done
}

# package_list GRUPO...: los paquetes de los repos de esos grupos (sin comentarios).
package_list() {
    local g
    for g in "$@"; do grep -vE '^\s*(#|$)' "${INSTALL_DIR:-$REPO_DIR/install}/packages/$g.txt" | awk '{print $1}'; done
}
