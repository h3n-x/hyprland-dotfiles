# shellcheck shell=bash
# shellcheck disable=SC2034  # DISTRO_*, INIT, AUR_HELPER y MIN_VERSIONS los usa quien carga la libreria
# Deteccion del sistema (Fase 19). Se carga con `source`; las pruebas cambian OS_RELEASE y INIT_PROC.

# Distribucion: DISTRO_ID, DISTRO_LIKE (de os-release) y DISTRO_GROUP (arch | arch-alike | other).
detect_distro() {
    local f=${OS_RELEASE:-/etc/os-release}
    DISTRO_ID=$(awk -F= '/^ID=/{gsub(/["'\'']/,"",$2); print tolower($2)}' "$f" 2>/dev/null)
    DISTRO_LIKE=$(awk -F= '/^ID_LIKE=/{gsub(/["'\'']/,"",$2); print tolower($2)}' "$f" 2>/dev/null)
    DISTRO_NAME=$(awk -F= '/^PRETTY_NAME=/{gsub(/["'\'']/,"",$2); print $2}' "$f" 2>/dev/null)
    case "$DISTRO_ID" in
        arch|endeavouros|cachyos|manjaro|garuda|artix|arcolinux|rebornos|archcraft|blendos) DISTRO_GROUP=arch ;;
        *) if [[ " $DISTRO_LIKE " == *" arch "* ]]; then DISTRO_GROUP=arch-alike; else DISTRO_GROUP=other; fi ;;
    esac
}

# Sistema de init: INIT = systemd | openrc | runit | dinit | s6 | unknown. Primero el que corre
# (proceso 1); si no se sabe (contenedor, chroot de instalacion), el que esta instalado.
detect_init() {
    local p1; p1=$(cat "${INIT_PROC:-/proc/1/comm}" 2>/dev/null)
    INIT_RUNNING=true
    case "$p1" in
        systemd) INIT=systemd; return ;;
        openrc-init|openrc) INIT=openrc; return ;;
        runit) INIT=runit; return ;;
        dinit) INIT=dinit; return ;;
        s6-svscan) INIT=s6; return ;;
    esac
    INIT_RUNNING=false
    # El binario del init instalado, no el nombre de un paquete: en Artix artix-archlinux-support
    # provee "systemd" y "pacman -Qq systemd" da verdadero. Los de Artix primero.
    local r=${INIT_ROOT:-}
    if [ -x "$r/usr/bin/dinit" ]; then INIT=dinit
    elif [ -x "$r/usr/bin/openrc-init" ] || [ -x "$r/usr/bin/openrc" ]; then INIT=openrc
    elif [ -x "$r/usr/bin/runit" ]; then INIT=runit
    elif [ -x "$r/usr/bin/s6-svscan" ] && [ -d "$r/etc/s6" ]; then INIT=s6
    elif [ -x "$r/usr/lib/systemd/systemd" ]; then INIT=systemd
    else INIT=unknown; fi
}

# Ayudante de AUR: AUR_HELPER = el pedido (--aur-helper), yay o paru instalados, o vacio.
detect_aur_helper() {
    local h
    for h in ${AUR_HELPER:-} yay paru; do
        command -v "$h" >/dev/null 2>&1 && { AUR_HELPER=$h; return 0; }
    done
    AUR_HELPER=
    return 1
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

# Archivos que su app reemplaza por una copia propia (xfconfd reescribe el de Thunar): el choque
# con stow es esperable; el instalador los deja como estan y doctor solo lo anota.
REWRITTEN='.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml'

# package_list GRUPO...: los paquetes de los repos de esos grupos (sin comentarios).
package_list() {
    local g
    for g in "$@"; do grep -vE '^\s*(#|$)' "${INSTALL_DIR:-$REPO_DIR/install}/packages/$g.txt" | awk '{print $1}'; done
}

# Grupos de un perfil: minimal = el escritorio; full = + desarrollo y apps. WITH/WITHOUT
# (listas separadas por comas) suman o quitan grupos. Los de aur.txt siguen al suyo (fonts = siempre).
profile_groups() {
    local profile=${1:-full} g res=() add del
    res=(core shell-tools fonts-themes)
    [ "$profile" = full ] && res+=(dev apps)
    IFS=, read -ra add <<<"${WITH:-}"
    IFS=, read -ra del <<<"${WITHOUT:-}"
    for g in "${add[@]}"; do [[ " ${res[*]} " == *" $g "* ]] || res+=("$g"); done
    for g in "${res[@]}"; do [[ " ${del[*]} " == *" $g "* ]] || printf '%s\n' "$g"; done
}
