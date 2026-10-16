# shellcheck shell=bash
# ./install.sh uninstall (Fase 19 B2): deshace lo que hizo el instalador. Quita los enlaces,
# devuelve el ultimo respaldo y (si se acepta) los paquetes que el instalador agrego y que nada
# mas necesita. No toca tus datos: wallpapers, opciones (settings.json), qt5ct/qt6ct, caches.

step_uninstall() {
    local pkgs backup f rel n=0
    mapfile -t pkgs < <(stow_packages)
    info "Removing the configuration links"
    do_ stow -D -d "$REPO_DIR" -t "$HOME" "${pkgs[@]}" || warn "stow could not remove every link"
    done_ "Configuration links removed"

    backup=$(find "$STATE" -maxdepth 1 -type d -name 'backup-*' 2>/dev/null | sort | tail -1)
    if [ -n "$backup" ] && ask y "Restore your files from %1?" "$backup"; then
        while IFS= read -r -d '' f; do
            rel=${f#"$backup"/}
            if [ -e "$HOME/$rel" ] || [ -L "$HOME/$rel" ]; then warn "%1 exists: left in the backup" "$HOME/$rel"; continue; fi
            do_ mkdir -p "$HOME/$(dirname "$rel")"
            do_ mv "$f" "$HOME/$rel" && n=$((n + 1))
        done < <(find "$backup" \( -type f -o -type l \) -print0)
        done_ "Restored %1 files from %2" "$n" "$backup"
    fi

    local rec="$STATE/installed-packages" still=()
    if [ -s "$rec" ]; then
        while read -r f; do pkg_installed "$f" && still+=("$f"); done < "$rec"
        if [ ${#still[@]} -gt 0 ] && ask n "Remove the %1 packages the installer added (only those nothing else needs)?" "${#still[@]}"; then
            # -u: solo los que ningun otro paquete necesita; el resto se queda.
            do_ sudo pacman -Rsnu --noconfirm "${still[@]}" && do_ rm -f "$rec"
            done_ "Removed the packages the installer added"
        else
            skipped "Packages (list in %1)" "$rec"
        fi
    fi
    do_ rm -f "$STATE/hypr-gpu.lua" "$STATE/install-profile"
    return 0
}
