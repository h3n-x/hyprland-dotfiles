#!/usr/bin/env bash
# Revision de una instalacion (Fase 19): ./install.sh doctor, o este archivo directo. No cambia
# nada. Problemas = lo que rompe algo (salida 1); notas = lo que conviene saber (no fallan).
#
# Revisa: paquetes del perfil y versiones minimas, servicios, enlaces de stow, caches de
# matugen, copias de root de los scripts sync-*, rutas de home de otro usuario en los archivos
# enlazados, el archivo de GPU (gpu-setup) y la config de Qt (qt5ct/qt6ct).
# Pruebas: INSTALL_DIR (este instalador), REPO_DIR (los dotfiles), GPU_SETUP, HOME, DOCTOR_SKIP (lista separada por espacios: packages services stow
# caches root paths gpu qt).
set -uo pipefail

INSTALL_DIR=${INSTALL_DIR:-$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")}
REPO_DIR=${REPO_DIR:-$(dirname "$INSTALL_DIR")}
GPU_SETUP=${GPU_SETUP:-$REPO_DIR/hypr/.config/hypr/scripts/gpu-setup}
DRY=true   # lo leen las librerias (do_ y qt_config no cambian nada)
export DRY
# shellcheck source=lib/ui.sh
. "$INSTALL_DIR/lib/ui.sh"
# shellcheck source=lib/detect.sh
. "$INSTALL_DIR/lib/detect.sh"
# shellcheck source=lib/qt.sh
. "$INSTALL_DIR/lib/qt.sh"

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
problems=0
notes=0
problem() { warn "$@"; problems=$((problems + 1)); }
note() { printf '\033[2m ·\033[0m %s\n' "$(tr_ "$@")"; notes=$((notes + 1)); }
skip() { [[ " ${DOCTOR_SKIP:-} " == *" $1 "* ]]; }

detect_distro
detect_init

# ---- Paquetes y versiones ----
if ! skip packages; then
    info "Packages"
    profile=$(cat "$STATE/install-profile" 2>/dev/null || echo full)
    groups=(core shell-tools fonts-themes)
    [ "$profile" = full ] && groups+=(dev apps)
    missing=()
    while read -r p; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done < <(package_list "${groups[@]}")
    # AUR: el paquete o su alternativa de los repos (los grupos del perfil).
    while read -r p g alt _; do
        case "$g" in fonts) ;; apps) [ "$profile" = full ] || continue ;; *) continue ;; esac
        pacman -Qq "$p" >/dev/null 2>&1 || { [ "$alt" != - ] && pacman -Qq "$alt" >/dev/null 2>&1; } || missing+=("$p")
    done < <(grep -vE '^\s*(#|$)' "$INSTALL_DIR/packages/aur.txt")
    if [ ${#missing[@]} -eq 0 ]; then ok "All packages of the %1 profile are installed" "$profile"
    else problem "Missing packages (%1): %2" "$profile" "${missing[*]}"; fi
    for mv in $MIN_VERSIONS; do
        p=${mv%%:*}; min=${mv#*:}; v=$(pkg_version "$p")
        if [ -z "$v" ]; then continue
        elif version_at_least "$p" "$min"; then ok "%1 %2 (needs %3 or newer)" "$p" "$v" "$min"
        else problem "%1 %2 is too old: the configuration needs %3 or newer" "$p" "$v" "$min"; fi
    done
fi

# ---- Servicios ----
if ! skip services; then
    info "Services"
    if [ "$INIT" = systemd ]; then
        for s in NetworkManager bluetooth; do
            if systemctl is-enabled --quiet "$s" 2>/dev/null; then ok "%1 is enabled" "$s"
            else problem "%1 is not enabled (the shell's network/bluetooth menus need it)" "$s"; fi
        done
        if systemctl is-enabled --quiet power-profiles-daemon 2>/dev/null; then ok "%1 is enabled" power-profiles-daemon
        elif systemctl is-enabled --quiet tlp 2>/dev/null; then note "tlp manages power: the power-profile menu won't change anything"
        else problem "%1 is not enabled (power profiles, game mode)" power-profiles-daemon; fi
        if systemctl is-enabled --quiet sddm 2>/dev/null; then ok "%1 is enabled" sddm
        else note "SDDM is not the login manager: the dotfiles-login screen won't show (optional system step)"; fi
    else
        note "Init system %1: services aren't checked yet" "$INIT"
    fi
fi

# ---- Enlaces de stow ----
if ! skip stow; then
    info "Configuration links"
    bad=()
    # Archivos que su app reemplaza por una copia propia (xfconfd reescribe el de Thunar): el
    # conflicto es esperable y no rompe nada.
    rewritten='\.config/xfce4/xfconf/xfce-perchannel-xml/thunar\.xml'
    for pkg in $(stow_packages); do
        out=$(stow -n -v -d "$REPO_DIR" -t "$HOME" "$pkg" 2>&1)
        grep -qE '^LINK:|conflict|existing target' <<<"$out" || continue
        if ! grep -qE '^LINK:' <<<"$out" && ! grep -E 'existing target' <<<"$out" | grep -qvE "$rewritten"; then
            note "%1: the app replaced its linked file with its own copy (harmless)" "$pkg"
        else
            bad+=("$pkg")
        fi
    done
    if [ ${#bad[@]} -eq 0 ]; then ok "Every configuration package is linked"
    else problem "Not linked or in conflict: %1 (run: ./install.sh files)" "${bad[*]}"; fi
fi

# ---- Caches de matugen ----
if ! skip caches; then
    info "Colors"
    c="${XDG_CACHE_HOME:-$HOME/.cache}/matugen"
    miss=()
    for f in status.json code.json quickshell-colors.json; do [ -s "$c/$f" ] || miss+=("$f"); done
    if [ ${#miss[@]} -eq 0 ]; then ok "The palette has been generated"
    else problem "Missing in %1: %2 (pick a wallpaper with Super+Shift+W, or run: ./install.sh first-run)" "$c" "${miss[*]}"; fi
fi

# ---- Copias de root de los scripts sync-* ----
if ! skip root; then
    info "System copies"
    for t in sddm plymouth grub; do
        dst=/usr/local/bin/sync-$t-theme; src="$REPO_DIR/hypr/.config/hypr/scripts/sync-$t-theme.sh"
        if [ ! -e "$dst" ]; then note "%1 isn't installed (optional system step)" "$dst"
        elif [ "$(sha256sum < "$dst")" = "$(sha256sum < "$src")" ]; then ok "%1 matches the repository" "$dst"
        else problem "%1 differs from the repository: reinstall it with: sudo install -m755 %2 %1" "$dst" "$src"; fi
    done
fi

# ---- Rutas de home de otro usuario en lo que se enlaza ----
if ! skip paths; then
    info "Paths"
    mapfile -t pkgs < <(stow_packages)
    hits=$(cd "$REPO_DIR" && git ls-files -- "${pkgs[@]}" 2>/dev/null | xargs -r grep -lE "/home/[a-z_][a-z0-9_-]*/" 2>/dev/null \
        | xargs -r grep -nE "/home/[a-z_][a-z0-9_-]*/" 2>/dev/null | grep -v "$HOME/" || true)
    if [ -z "$hits" ]; then ok "No file points to another user's home"
    else problem "Files with another user's home: %1" "$(cut -d: -f1,2 <<<"$hits" | tr '\n' ' ')"; fi
fi

# ---- GPU ----
if ! skip gpu; then
    info "Graphics"
    if "$GPU_SETUP" --check >/dev/null 2>&1; then ok "The GPU variables match this machine"
    else problem "The GPU variables are missing or outdated (run: ~/.config/hypr/scripts/gpu-setup --write, then log in again)"; fi
fi

# ---- Qt ----
if ! skip qt; then
    info "Qt"
    if qt_config --check 2>/dev/null; then ok "qt5ct and qt6ct point to your palette"
    else problem "The Qt configuration needs fixing (run: ./install.sh files)"; fi
fi

echo
if [ $problems -eq 0 ]; then ok "No problems (%1 notes)" "$notes"; exit 0; fi
err "%1 problems, %2 notes" "$problems" "$notes"
exit 1
